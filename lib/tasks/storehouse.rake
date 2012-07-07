namespace :storehouse do
  task :clear => :environment do
    Storehouse.clear!
  end
end