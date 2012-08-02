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
        bucket.get(path).data
      rescue # any error coming from the client will be consumed
        nil
      end

      def write(path, content, options = {})
        object = bucket.get_or_new(path)
        object.content_type = 'text/plain'
        object.data = content
        object.store
      end

      def delete(path)
        bucket.delete(path)
      end

      def clear!(pattern = nil)
        bucket.keys do |k|
          delete(k) if k.present? && (pattern.nil? || k.to_s =~ pattern)
        end
      end

    end
  end
end