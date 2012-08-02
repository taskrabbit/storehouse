namespace :storehouse do
  task :clear => :environment do
    Storehouse.clear!
  end


  namespace :riak do

    task :clear_expired => :environment do 

      raise "Storehouse not configured with Riak Adapter" unless Storehouse.config.adapter == 'Riak'

      t = Time.now.to_i

      adapter = Storehouse.send(:data_store)
      bucket = adapter.send(:bucket)

      bucket.get_index('expires_at_int', 20.years.ago.to_i...t).each do |k|
        bucket.delete(k)
      end
    end

  end

end