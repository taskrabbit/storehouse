require 'spec_helper'

describe UsersController do
  ENV['RAILS_VERSION'] == '2' ? integrate_views : render_views

  before do
    @user = User.last || User.create(:first_name => 'Gerry', :last_name => 'Philmore')
    Storehouse.configure do |config|
      config.adapter = 'InMemory'
      config.except = /\/account/
      config.hook_controllers!
    end
  end

  context 'caching' do

    before do

      original_method = controller.method(:cache_page)
      controller.should_receive(:cache_page).once do |*args|
        original_method.call(*args)
      end

    end

    it "should execute caching on show" do
      show_text = "<h2>User#show: #{@user.name}</h2>"

      original_method = Storehouse.send(:data_store).method(:write)
      Storehouse.send(:data_store).should_receive(:write).with("/users/#{@user.id}", show_text, {}).once do |path, content, options|
        original_method.call(path, content, options)
      end

      get :show, :id => @user
      
      Storehouse.read("/users/#{@user.id}").should eql(show_text)
    end

    it 'should execute caching on index but expire in 10 minutes' do
      index_text = '<h2>User#index</h2>'

      original_method = Storehouse.send(:data_store).method(:write)
      Storehouse.send(:data_store).should_receive(:write).with("/users", index_text, :expires_in => 10.minutes).once do |path, content, options|
        original_method.call(path, content, options)
      end


      get :index

      response.body.should include(index_text)

    end

    it 'should not execute caching on account because of the config' do
      Storehouse.send(:data_store).should_receive(:write).never
      get :account, :id => @user
    end
  end

  context 'expiration' do

    before do
      get :show, :id => @user
      response.should be_success

      Storehouse.read("/users/#{@user.id}").should_not be_blank
    end

    it 'should expire the cache when the user is updated' do
      Storehouse.send(:data_store).should_receive(:delete).with("/users/#{@user.id}").once
      Storehouse.send(:data_store).should_receive(:delete).with("/users").once
      
      get :touch, :id => @user
    end

  end

  context 'bypassing storehouse' do

    it 'should not attempt to send the cache to storehouse if the :storehouse option is false' do
      Storehouse.send(:data_store).should_receive(:write).never

      get :settings, :id => @user
      response.should be_success

    end

  end

end