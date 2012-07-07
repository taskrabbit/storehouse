Storehouse.configure do |config|
  config.adapter = 'Riak'
  config.hook_controllers!
end