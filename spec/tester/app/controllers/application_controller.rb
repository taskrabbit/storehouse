class ApplicationController < ActionController::Base

  caches_page :show, :account, :root, :if => :should_cache?
  caches_page :index, :expires_in => 600, :if => :should_cache?
  caches_page :settings, :storehouse => false, :if => :should_cache?

  def index
    render :text => 'application/index', :layout => false
  end

  def root_response
    render :text => request.query_string, :layout => false
  end

  def show
    render :text => "application/show/#{params[:id]}", :layout => false
  end

  def account
    render :text => 'application/account', :layout => false
  end

  def settings
    render :text => 'application/settings', :layout => false
  end

  def touch
    expire_page("/application/index")
    expire_page("/application/#{params[:id]}/show")
    head :ok
  end

  protected

  def should_cache?
    request.query_string.blank?
  end


end
