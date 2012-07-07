class UsersController < ApplicationController

  caches_page :index, :show, :account
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

  def touch
    @user = User.find(params[:id])
    @user.update_attributes(:updated_at => Time.now)
    redirect_to :action => :show
  end

end