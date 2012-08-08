require 'riak'

module Storehouse
  module Adapter
    class Riak < Base

      def initialize(options = {})
        super
        @bucket_name = options[:bucket] || ['_page_cache', Storehouse.config.scope].compact.join('_')
        @client_options = options[:client] || {}
        @clearing_delta = options[:clearing_delta] || 1.week
      end

      protected

      def bucket
        @bucket ||= ::Riak::Client.new(@client_options).bucket(@bucket_name)
      end

      def read(path)
        object = bucket.get(path)
        
        expiration = object.indexes['expires_at_int']
        expiration = expiration.first if expiration.respond_to?(:first) # might come back as a Set

        if expiration && expiration < Time.now.to_i
          object.indexes['expires_at_int'] = Time.now.to_i + 10
          nil
        else
          object.data
        end
      rescue # any error coming from the client will be consumed
        nil
      end

      def write(path, content, options = {})
        
        object = bucket.get_or_new(path)
        object.content_type = 'text/plain'
        object.data = content

        
        expiration = expires_at(options)
        object.indexes['expires_at_int'] = expiration.try(:to_i)
        object.indexes['created_at_int'] = Time.now.to_i

        object.store
      
      end

      def delete(path)
        bucket.delete(path)
      end

      def clear!(pattern = nil)
        chunked_delete('created_at_int', 1.year.ago)
      end

      def clear_expired!
        chunked_delete('expired_at_int', 1.year.ago)
      end

      def chunked_delete(index_name, start_time, end_time = nil)
        t = end_time || Time.now
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

    end
  end
end