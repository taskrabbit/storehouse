Mockery3::Application.routes.draw do
  resources :users, :only => [:index, :show]
  get '/:controller/:id/:action'
  root :to => 'users#index'
end
