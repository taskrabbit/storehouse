require 'riak'

module Storehouse
  module Adapter
    class Riak < Base

      def initialize(options = {})
        super
        @bucket_name = options[:bucket] || ['_page_cache', Storehouse.config.scope].compact.join('_')
        @client_options = options[:client] || {}
      end

      protected

      def bucket
        @bucket ||= ::Riak::Client.new(@client_options).bucket(@bucket_name)
      end

      def read(path)
        object = bucket.get(path)
        
        expiration = object.indexes['expires_at_int']
        expiration = expiration.first if expiration.respond_to?(:first)

        if expiration && expiration < Time.now.to_i
          delete(path)
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

        
        if expiration = expires_at(options)
          object.indexes['expires_at_int'] = expiration.to_i
        end

        object.store
      
      end

      def delete(path)
        bucket.delete(path)
      end

      def clear!(pattern = nil)
        bucket.delete(pattern)
      end

    end
  end
end