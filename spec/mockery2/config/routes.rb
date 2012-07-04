ActionController::Routing::Routes.draw do |map|
  map.resources :users, :only => [:index, :show], :member => {:account => :get}
  map.root :controller => 'users', :action => 'index'
end
