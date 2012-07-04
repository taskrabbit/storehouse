require 'spec_helper'

describe 'Rails integration for testing' do

  it 'should be able to setup the middleware' do
    get_storehouse_middleware.should_not be_blank
  end

  it 'should have set up the middleware with the default options' do
    mid = get_storehouse_middleware
    mid.args.first.should eql('Base')
  end

  it 'should be able to change the adapter' do
    use_middleware_adapter!('Dalli')
    get_storehouse_middleware.args.first.should eql('Dalli')
  end

end