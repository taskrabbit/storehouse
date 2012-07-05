require 'spec_helper'

describe UsersController, :type => :controller do
  integrate_views

  before do
    @user = User.last || User.create(:first_name => 'Gerry', :last_name => 'Philmore')
    Storehouse.configure do |config|
      config.except = /\/account/
      config.hook_controllers!
    end

    original_method = controller.method(:cache_page)
    controller.should_receive(:cache_page).once do |*args|
      original_method.call(*args)
    end

  end

  it "should execute caching on show" do
    Storehouse.data_store.should_receive(:write).with("/users/#{@user.id}", "<h2>User#show: #{@user.name}</h2>")
    get :show, :id => @user
  end

  it 'should not execute caching on account because of the config' do
    Storehouse.data_store.should_receive(:write).never
    get :account, :id => @user
  end


end