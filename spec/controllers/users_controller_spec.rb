require 'spec_helper'

describe 'Controller Usage' do

  class UsersController < ActionController::Base

    layout false

    caches_page :show, :account, :root, :if => :should_cache?
    caches_page :index, :expires_in => 600
    caches_page :settings, :storehouse => false
    
    def index
      render :text => 'users/index'
    end

    def root
      render :text => request.query_string
    end

    def show
      render :text => "users/show/#{params[:id]}"
    end

    def account
      render :text => 'users/account'
    end

    def settings
      render :text => 'users/settings'
    end

    protected

    def should_cache?
      request.query_string.blank?
    end
  end

  let(:controller){ UsersController.new }

  before do
    Storehouse.configure do
      adapter  'InMemory'
      except!(   /\/account/)
    end
  end

  context 'caching' do

    before do

      original_method = controller.method(:cache_page)
      controller.should_receive(:cache_page).once do |content, path, gzip|
        original_method.call(content, path, gzip)
      end

    end

    it "should execute caching on show" do
      user_id = 544
      show_text = "users/show/#{user_id}"

      original_method = Storehouse.send(:data_store).method(:write)
      Storehouse.send(:data_store).should_receive(:write).with("/users/#{user_id}", show_text, {}).once do |path, content, options|
        original_method.call(path, content, options)
      end

      get :show, :id => user_id
      
      Storehouse.read("/users/#{user_id}").should eql(show_text)
    end

    it 'should execute caching on index but expire in 10 minutes' do
      index_text = 'users/index'

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