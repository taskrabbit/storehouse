require 'spec_helper'

describe UsersController do
  integrate_views

  module Storehouse
    module Adapter
      class InMemoryHash < Base

        attr_reader :content
        def initialize(options = {})
          super
          @content = {}
        end

        def write(key, val)
          self.content[key] = val
        end

        def delete(key)
          self.content.delete(key)
        end

        def read(key)
          self.content[key]
        end

      end
    end
  end

  before do
    @user = User.last || User.create(:first_name => 'Gerry', :last_name => 'Philmore')
    Storehouse.configure do |config|
      config.adapter = 'InMemoryHash'
      config.except = /\/account/
      config.hook_controllers!
    end

    original_method = controller.method(:cache_page)
    controller.should_receive(:cache_page).once do |*args|
      original_method.call(*args)
    end

  end

  it "should execute caching on show" do
    show_text = "<h2>User#show: #{@user.name}</h2>"

    original_method = Storehouse.data_store.method(:write)
    Storehouse.data_store.should_receive(:write).with("/users/#{@user.id}", show_text).once do |path, content|
      original_method.call(path, content)
    end

    get :show, :id => @user
    
    Storehouse.read("/users/#{@user.id}").should eql(show_text)
  end

  it 'should not execute caching on account because of the config' do
    Storehouse.data_store.should_receive(:write).never
    get :account, :id => @user
  end


end