class UserSweeper < ActionController::Caching::Sweeper
  observe User

  def after_update(user)
    expire_page(:controller => 'users', :action => 'show', :id => user)
    expire_page(:controller => 'users', :action => 'index')
  end
  
end