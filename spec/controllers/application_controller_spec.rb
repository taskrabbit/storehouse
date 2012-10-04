require 'spec_helper'

describe ApplicationController do

  before do
    Storehouse.configure do
      adapter  'InMemory'
      except(/\/account/)
    end
  end

  let(:id){ 544 }

  context 'caching' do

    before do

      original_method = controller.method(:cache_page)
      controller.should_receive(:cache_page).once do |*args|
        original_method.call(*args)
      end

    end

    it "should execute caching on show" do
      show_text = "application/show/#{id}"

      original_method = Storehouse.send(:data_store).method(:write)
      Storehouse.send(:data_store).should_receive(:write).with("/application/#{id}/show", show_text, {}).once do |path, content, options|
        original_method.call(path, content, options)
      end

      get :show, :id => id
      
      Storehouse.read("/application/#{id}/show").should eql(show_text)
    end

    it 'should execute caching on index but expire in 10 minutes' do
      index_text = 'application/index'

      original_method = Storehouse.send(:data_store).method(:write)
      Storehouse.send(:data_store).should_receive(:write).with("/application/index", index_text, :expires_in => 10.minutes).once do |path, content, options|
        original_method.call(path, content, options)
      end


      get :index

      response.body.should include(index_text)

    end

    it 'should not execute caching on account because of the config' do
      Storehouse.send(:data_store).should_receive(:write).never
      get :account, :id => id
    end
  end

  context 'expiration' do

    before do
      get :show, :id => id
      response.should be_success

      Storehouse.read("/application/#{id}/show").should_not be_blank
    end

    it 'should expire the cache when the user is updated' do
      Storehouse.send(:data_store).should_receive(:delete).with("/application/#{id}/show").once
      Storehouse.send(:data_store).should_receive(:delete).with("/application/index").once
      
      get :touch, :id => id
    end

  end

  context 'bypassing storehouse' do

    it 'should not attempt to send the cache to storehouse if the :storehouse option is false' do
      Storehouse.send(:data_store).should_receive(:write).never

      get :settings, :id => id
      response.should be_success

    end

  end

end