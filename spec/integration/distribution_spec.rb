require 'spec_helper'

describe 'cache distribution' do

  let(:user_id){ 535 }
  let(:cache_dir){ Rails.root.join('public', 'application') }
  let(:path){ Rails.root.join('public', 'application', "#{user_id}", 'show.html') }
  let(:object_path) { "/application/#{user_id}/show" }
  
  before do
    Storehouse.configure do
      adapter 'InMemory'
      distribute(/application\/[0-9]+\/show$/)
    end
  end

  after do
    `rm -r #{cache_dir}` rescue nil
  end


  it 'should write the file if the configuration chooses to distribute' do

    get object_path

    File.file?(path).should be_true
    File.delete(path)
  end

  it 'should write the file if the content is in the cache but not on the server' do

    Storehouse.write(object_path, 'This is the content')
    Storehouse.config.consider_caching?(object_path).should be_true
    Storehouse.read(object_path).should eql('This is the content')
  
    get object_path

    response.body.should eql('This is the content')
    File.file?(path).should be_true
  end

  context 'with a reheat param' do

    before do

      id = user_id
      Storehouse.configure do
        adapter 'InMemory'
        distribute "/application/#{id}/index"
        reheat_parameter 'reheatme'
      end
    end

    it 'should strip the query string when the reheat param is set' do
      get "/application/#{user_id}/index?reheat_me=true"
      response.body.should eql('application/index')
    end

    it 'should write to the file system after passing through a distributed path' do
      ActionController::Base.should_receive(:cache_page)
      get "/application/#{user_id}/index?reheatme=true"
    end

    it 'should not write a file when more params are present' do
      ActionController::Base.should_receive(:cache_page).never
      get "/application/#{user_id}/index?reheatme=true&hey=something"
    end

  end

end