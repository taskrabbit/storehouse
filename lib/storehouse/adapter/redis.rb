require 'redis'

module Storehouse
  module Adapter
    class Redis < Base

      def initialize(options = {})
        super
        @client_options = options[:client] || {}
        @namespace = options[:namespace] || ['_page_cache', Storehouse.config.scope].compact.join('_')
        connect!
      end

      def connect!
        @client ||= begin
          ::Redis.new(@client_options)
        end
      end 

      protected

      def read(path)
        @client.get(path)
      end

      def write(path, content, options = {})
        @client.set(path, content)
      end

      def delete(path)
        @client.del(path)
      end

      def clear!
        keys = @client.keys("#{@namespace}::*")
        @client.del(*keys)
      end

      protected

      def scoped_key(path)
        [@namespace, path].compact.join('::')
      end

    end
  end
end