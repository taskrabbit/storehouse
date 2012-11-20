require 'spec_helper'

describe 'Storehouse expiration' do

  let(:mid){ Storehouse::Middleware.new(app) }
  let(:app){ lambda{|request| [200, {'X-Storehouse' => '1'}, ['some other content']] }}
  let(:req){ {'REQUEST_URI' => '/path/to/content'} }
  let(:bot){ req.merge({'User-Agent' => 'GoogleBot 2.1'}) }
  let(:reheat){ req.merge({'QUERY_STRING' => 'reheat_cache=true'}) }

  context 'dealing with object expiration' do

    it 'should serve content that\'s not expired' do
      obj = Storehouse.write('/path/to/content.html', 200, {}, 'test content')
      Storehouse.stub(:read).with('/path/to/content.html').and_return(obj)

      response = mid.call(req)
      response[2].should eql(['test content'])
    end

    it 'should not serve expired content' do
      obj = Storehouse.write('/path/to/content.html', 200, {}, 'test content')
      Storehouse.stub(:read).with('/path/to/content.html').and_return(obj)
      obj.stub(:expired?).and_return(true)

      response = mid.call(req)
      response[2].should eql(['some other content'])
    end

    it 'should serve expired content to bots if configured to do so' do
      gem_config(:bot)

      obj = Storehouse.write('/path/to/content.html', 200, {}, 'test content')
      Storehouse.stub(:read).with('/path/to/content.html').and_return(obj)
      obj.stub(:expired?).and_return(true)

      response = mid.call(bot)
      response[2].should eql(['test content'])
    end
  end

  context 'dealing with reheat params' do

    before do
      gem_config(:reheat)

      obj = Storehouse.write('/path/to/content.html', 200, {}, 'test content')
      Storehouse.stub(:read).with('/path/to/content.html').and_return(obj)
      obj.should_not be_expired
    end

    it 'should rerender cached content when it\'s not expired but the reheat param is present' do
      Storehouse.should_receive(:write).once
      response = mid.call(reheat)
      response[2].should eql(['some other content'])
    end

    it 'should ignore the param if it\'s not the only one' do
      request = reheat
      request['QUERY_STRING'] << '&someother=param'

      mid.should_receive(:attempt_to_store).never

      response = mid.call(request)
      response[2].should eql(['some other content'])
    end

    it 'should observe it with other params if ignore_params is on' do
      gem_config(:reheat, :ignore)

      mid.should_receive(:attempt_to_store).once

      request = reheat
      request['QUERY_STRING'] << '&someother=param'

      response_val = app.call({})
      app.should_receive(:call).with({"REQUEST_URI"=>"/path/to/content", "QUERY_STRING"=>"someother=param"}).and_return(response_val)
      response = mid.call(request)
      response[2].should eql(['some other content'])
    end

  end

end