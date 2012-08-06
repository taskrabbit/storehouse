namespace :storehouse do
  task :clear => :environment do
    Storehouse.clear!
  end

  task :clear_expired => :environment do
    store = Storehouse.send(:data_store)
    store.send(:clear_expired!) if store.respond_to?(:clear_expired!)
  end

end