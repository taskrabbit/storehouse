Tester::Application.routes.draw do
  get '/:controller/:id/:action'
  get '/:controller/:action'
  root :to => 'application#root_response'
end