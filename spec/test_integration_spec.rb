require 'spec_helper'

describe 'Rails integration for testing' do

  it 'should be able to setup the middleware' do
    get_storehouse_middleware.should_not be_blank
  end

  it 'should use the default adapter' do
    Storehouse.data_store.class.name.should eql('Storehouse::Adapter::Base')
  end

  it 'should be able to change the adapter' do
    use_middleware_adapter!('Dalli')
    Storehouse.data_store.class.name.should eql('Storehouse::Adapter::Dalli')
  end

end