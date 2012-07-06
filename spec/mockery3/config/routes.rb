Mockery3::Application.routes.draw do
  resources :users, :only => [:index, :show]
  get '/users/:id/account' => 'users#account'
  root :to => 'users#index'
end
