module Storehouse
  class Railtie < Rails::Railtie
    config.app_middleware.use 'Storehouse::Middleware'
  end
end