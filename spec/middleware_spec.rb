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
end