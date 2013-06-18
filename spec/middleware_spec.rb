require 'spec_helper'

describe Storehouse::Middleware do

  let(:normal_request){ {'PATH_INFO' => '/path/for/something', 'response' => 'normal_response'} }
  let(:normal_response){ [200, {}, 'test response'] }

  let(:cache_request){ normal_request.merge('response' => 'cache_response') }
  let(:cache_response){ [200, {'X-Storehouse' => '1'}, 'test response'] }

  let(:expire_request){ normal_request.merge('response' => 'expire_response') }
  let(:expire_response){ 
    c = cache_response
    c[1].merge!('X-Storehouse-Expires-At' => '123456')
    c
  }

  let(:distribute_request){ normal_request.merge('response' => 'distribute_response') }
  let(:distribute_response){
    c = cache_response
    c[1].merge!('X-Storehouse-Distribute' => '1')
    c
  }

  let(:valid_subdomain_request){ normal_request.merge('HTTP_HOST' => 'a.test.com') }
  let(:invalid_subdomain_request){ normal_request.merge('HTTP_HOST' => 'd.test.com') }

  let(:app){ lambda{|req| send(req['response']) } }
  let(:middleware){ Storehouse::Middleware.new(app) }


  it 'should not invoke any storage for normal requests' do
    Storehouse.should_receive(:write).never
    Storehouse.should_receive(:postpone).never
    middleware.call(normal_request)
  end

  it 'should render the cached value when it\'s present and not expired' do

    object = Storehouse::Object.new(
      :status => 200, 
      :headers => {'Content-Type' => 'text/html'}, 
      :content => 'cached content'
    )

    Storehouse.should_receive(:read).with('/path/for/something').once.and_return(object)
    app.should_receive(:call).never

    result = middleware.call(normal_request)

    result.should eql(object.rack_response)
  end

  it 'should cache the response when told to' do
    Storehouse.should_receive(:write).with('/path/for/something', 200, {}, 'test response', nil)
    middleware.call(cache_request)
  end

  it "should cache the response using headers_to_store but return all headers" do
    app = lambda do |req|
      body = "test response"

      [200, {"Content-Type" => "text/plain", "Content-Length" => body.length.to_s, "X-Storehouse" => 32}, [body]]
    end
    middleware = Storehouse::Middleware.new(app)

    the_hash = {}
    middleware.should_receive(:headers_to_store).and_return(the_hash)
    Storehouse.should_receive(:write).with('/path/for/something', 200, the_hash, 'test response', nil)

    status, headers, content = middleware.call(cache_request)

    headers.keys.should =~ ["Content-Type", "Content-Length"]
  end

  it 'should cache the response with an expiration and drop storehouse headers' do
    Storehouse.should_receive(:write).with('/path/for/something', 200, {}, 'test response', '123456')
    status, headers, content = middleware.call(expire_request)
    headers.keys.should be_empty
  end

  it 'should distribute and keep storehouse distribution header' do
    Storehouse.should_receive(:write_file).with('/path/for/something', 'test response').once
    middleware.call(distribute_request)
    object = Storehouse.read('/path/for/something.html')
    object.headers.has_key?('X-Storehouse-Distribute').should be_true
  end

  it 'should not attempt to write to the store if the retrieval was a failure' do
    Storehouse.should_receive(:read).with('/path/for/something').and_return(nil)
    middleware.should_receive(:attempt_to_store).never
    Storehouse.should_receive(:write_file).once
    middleware.call(distribute_request)
  end

  it 'should not attempt to read from the store if a subdomain is defined' do
    Storehouse.should_receive(:read).never
    gem_config(:subdomain)
    middleware.call(invalid_subdomain_request)
  end

  it 'should attemt to read if a good subdomain is provided' do
    Storehouse.should_receive(:read).once
    gem_config(:subdomain)
    middleware.call(valid_subdomain_request)
  end

  it 'should determine subdomain validity correct' do
    Storehouse.stub(:subdomains).and_return(['www'])
    middleware.send(:valid_subdomain?, {'HTTP_HOST' => 'www.google.com'}).should be_true
    middleware.send(:valid_subdomain?, {'HTTP_HOST' => 'wwww.google.com'}).should be_false
    middleware.send(:valid_subdomain?, {'HTTP_HOST' => 'x.google.com'}).should be_false

  end

  describe "#headers_to_store" do
    let(:middleware) { Storehouse::Middleware.new(app) }

    before do
      Storehouse.set_spec({
        'enabled' => true,
        'ignore_headers' => ['Ignored-Header']
      })
    end

    it "excludes storehouse headers" do
      middleware.send(:headers_to_store, {
        "X-Storehouse"            => 'test',
        "X-Storehouse-Expires-At" => "test"
      }).should == {}
    end

    it "excludes Set-Cookie" do
      middleware.send(:headers_to_store, {
        "Set-Cookie" => 'test'
      }).should == {}
    end

    it "excludes ignore_headers from configuration" do
      middleware.send(:headers_to_store, {
        "Ignored-Header" => 'value'
      }).should == {}
    end

    it "does not exclude the rest" do
      middleware.send(:headers_to_store, {
        "Other-Header" => 'value'
      }).should == { "Other-Header" => 'value' }
    end
  end
end