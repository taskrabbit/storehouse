class UsersController < ApplicationController

  caches_page :index, :show

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def account
    @user = User.find(params[:id])
    
  end

end