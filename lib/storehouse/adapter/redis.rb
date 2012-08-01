require 'redis'

module Storehouse
  module Adapter
    class Redis < Base

      def initialize(options = {})
        super
        @client_options = options[:client] || {}
        @namespace = options[:namespace] || ['_page_cache', Storehouse.config.scope].compact.join('_')
      end

      protected

      def read(path)
        client.get(path)
      end

      def write(path, content, options = {})
        client.set(path, content)
      end

      def delete(path)
        client.del(path)
      end

      def clear!(pattern = nil)
        keys = @client.keys("#{@namespace}::#{pattern || '*'}")
        client.del(*keys)
      end

      def client
        @client ||= begin
          ::Redis.new(@client_options)
        end
      end 

      def scoped_key(path)
        [@namespace, path].compact.join('::')
      end

    end
  end
end