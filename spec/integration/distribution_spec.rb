require 'spec_helper'

describe 'distribution' do

  let(:path){ Rails.root.join('public', 'cache', 'users', "#{@user.id}.html") }
  let(:user_path) { "/users/#{@user.id}" }
  
  before do
    @user = User.last || User.create(:first_name => 'Gerry', :last_name => 'Philmore')
    Storehouse.configure do |c|
      c.adapter = 'InMemory'
      c.distribute!(/users\/[0-9]+$/)
      c.hook_controllers!
    end
    File.delete(path) if File.file?(path)
  end


  it 'should write the file if the configuration chooses to distribute' do
    get user_path

    File.file?(path).should be_true
    File.delete(path)
  end

  it 'should write the file if the content is in the cache but not on the server' do

    Storehouse.write(user_path, 'This is the content')
    Storehouse.config.consider_caching?(user_path).should be_true
    Storehouse.read(user_path).should eql('This is the content')
  
    get user_path

    response.body.should eql('This is the content')
    File.file?(path).should be_true
  end

end