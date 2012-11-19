module Storehouse
  class Railtie < Rails::Railtie
    config.app_middleware.insert 0, 'Storehouse::Middleware'
  end
end