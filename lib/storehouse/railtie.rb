module Storehouse
  class Railtie < Rails::Railtie
    config.app_middleware.use 'Storehouse::Middleware'

    initializer 'storehouse.hook_controllers' do |app|
      ActiveSupport.on_load(:action_controller) do
        ActionController::Base.extend Storehouse::Controller
      end
    end
  end
end