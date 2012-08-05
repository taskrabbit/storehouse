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

      t0 = 1.year.ago

      # chunked expiration. 1 month timespan for each key retrieval
      begin

        t1 = t0 + 1.month
        t1 = [t1, t].min

        bucket.get_index('expires_at_int', t0.to_i...t1.to_i).each do |k|
          bucket.delete(k)
        end

        t0 += 1.month

      end while(t0 < t)


    end

  end

end