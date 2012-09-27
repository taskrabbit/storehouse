Tester::Application.routes.draw do
  get '/:controller/:action'
  get '/:controller/:id/:action'
  root :to => 'application#root_response'
end