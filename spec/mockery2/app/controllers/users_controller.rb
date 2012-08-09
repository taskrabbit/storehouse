class UsersController < ApplicationController

  caches_page :show, :account
  caches_page :index, :expires_in => 10.minutes
  caches_page :settings, :storehouse => false
  cache_sweeper :user_sweeper, :only => [ :touch ]
  
  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def account
    @user = User.find(params[:id])
  end

  def settings
    @user = User.find(params[:id])
    render :text => 'settings'
  end

  def touch
    @user = User.find(params[:id])
    @user.update_attributes(:updated_at => Time.now)
    redirect_to :action => :show
  end

end