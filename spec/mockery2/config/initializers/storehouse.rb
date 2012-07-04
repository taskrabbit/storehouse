Storehouse.configure do |config|
  config.adapter = 'Base'
  config.except  = ['/tos', /\/account/]
end