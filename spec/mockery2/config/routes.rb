ActionController::Routing::Routes.draw do |map|
  map.resources :users, :only => [:index, :show]
  map.connect '/:controller/:id/:action'
  map.root :controller => 'users', :action => 'index'
end
