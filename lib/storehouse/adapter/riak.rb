require 'riak'

module Storehouse
  module Adapter
    class Riak < Base

      def initialize(options = {})
        super
        @bucket_name = options[:bucket] || ['_page_cache', Storehouse.config.scope].compact.join('_')
        @client_options = options[:client] || {:host => 'localhost', :http_port => '8098'}
        @clearing_delta = options[:clearing_delta] || 7*24*60*60 # 1.week
        @nonstop = options[:non_stop]
      end

      protected

      def bucket
        @bucket ||= ::Riak::Client.new(@client_options).bucket(@bucket_name)
      end

      def read(path)
        object = bucket.get(path)
        
        expiration = value_from_index(object, 'expires_at_int')

        # if it's expired
        if expiration && expiration < Time.now.to_i

          return nil unless nonstop?
            
          currently_attempting = value_from_index(object, 'attempting_int').to_i > 0
          return object.data if currently_attempting

          # make it so this object is now attempting to be updated
          set_index(object, 'attempting_int', 1)
          object.store

          # continue to return nil so hopefully this request will update the cache
          nil
        else
          object.data
        end
      rescue Exception => e # any error coming from the client will be consumed
        Storehouse.config.report_error(e) unless e.message.to_s =~ /not found/
        nil
      end

      def write(path, content, options = {})
        
        object = bucket.get_or_new(path)
        object.content_type = 'text/plain'
        object.data = content

        
        expiration = expires_at(options).try(:to_i)

        set_index(object, 'expires_at_int', expiration) if expiration
        set_index(object, 'created_at_int', Time.now.to_i)
        set_index(object, 'attempting_int', 0)

        object.store
      
      end

      def delete(path)
        bucket.delete(path)
      end

      def clear!(pattern = nil)
        chunked_delete('created_at_int', one_year_ago)
      end

      # the request that was attempting an update is finished
      # make sure we reset the index whether or not the bucket was updated with a new value
      def expire_nonstop_attempt!(path)
        object = bucket.get(path)
        if object.data
          set_index(object, 'attempting_int', 0)
          object.store
        end

      rescue Exception => e # 404's etc
        Storehouse.config.report_error(e)
        nil
      end

      def clear_expired!
        chunked_delete('expired_at_int', one_year_ago)
      end

      def chunked_delete(index_name, start_time, end_time = nil)
        t = end_time || Time.now.to_i
        t0 = start_time

        # chunked expiration. 1 @clearing_delta timespan for each key retrieval
        begin

          t1 = t0 + @clearing_delta
          t1 = [t1, t].min

          bucket.get_index(index_name, t0.to_i...t1.to_i).each do |k|
            puts "Storehouse deleting: #{k}"
            bucket.delete(k)
          end

          t0 += @clearing_delta

        end while(t0 < t)
      end

      def value_from_index(object, name)
        val = object.indexes[name]
        val.respond_to?(:first) ? val.first : val # might come back as a Set
      end

      def set_index(object, name, value)
        object.indexes[name] = Set.new([value])
      end

      def nonstop?
        !!@nonstop
      end

      def one_year_ago
        Time.now.to_i - 365*24*60*60
      end

    end
  end
end