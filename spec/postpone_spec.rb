require 'spec_helper'

describe 'Storehouse Postponing' do

  before do
    gem_config(:postpone)
  end

  let(:app){ lambda{ [200, {}, 'test'] } }
  let(:middleware){ Storehouse::Middleware.new(app) }
  let(:env){ {'REQUEST_URI' => '/path/to/something'} }

  it 'should not attempt to postpone an expired object unecessarily' do
    Storehouse.should_receive(:postpone).never
    Storehouse.stub(:postpone? => false)
    Storehouse::Object.any_instance.stub(:expired? => true, :blank? => false)
    middleware.call(env)
  end

  it 'should attempt to postpone the object if we\'re postponing' do
    object = stub(:blank? => false, :expired? => true)
    Storehouse.store.should_receive(:postpone).with(object).once
    Storehouse.store.should_receive(:read).and_return(object)
    middleware.call(env)
  end

  it 'should never postpone if we\'re told to render expired' do
    middleware.stub(:render_expired? => true)
    object = stub(:blank? => false, :expired? => true, :rack_response => app.call)
    Storehouse.store.should_receive(:read).and_return(object)
    Storehouse.store.should_receive(:postpone).never
    middleware.call(env)
  end

  
end