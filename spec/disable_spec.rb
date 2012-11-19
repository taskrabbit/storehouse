require 'spec_helper'

describe "Storehouse Disabling" do

  before do
    gem_config(:disabled)
  end

  it 'should disable everything at the top-level' do
    Storehouse.should_receive(:store).never
    Storehouse.read('test')
    Storehouse.write('test', 'value')
    Storehouse.delete('test')
    Storehouse.postpone('test')
    Storehouse.clear!
  end

  it 'should not invoke any middleware functionality when storehouse is disabled' do
    app = lambda{ [200, {}, 'hey'] }
    env = {}
    middleware = Storehouse::Middleware.new(app)

    middleware.should_receive(:storehouse_response).never

    middleware.call(env)
  end

  it 'should remove storehouse headers even when it\'s disabled' do
    app = lambda{ [200, {'X-Storehouse-Distribute' => '1'}, 'hey'] }
    env = {}
    middleware = Storehouse::Middleware.new(app)

    status, headers, content = middleware.call(env)

    headers.keys.should be_empty
  end

end