require 'redis'

module Storehouse
  module Adapter
    class Redis < Base

      def initialize(options = {})
        super
        @client_options = options['client'] || {}
        @namespace = options['namespace'] || ['_page_cache', Storehouse.config.scope].compact.join('_')
      end

      protected

      def read(path)
        client.get(path)
      end

      def write(path, content, options = {})
        time_to_live = ttl(options)
        if time_to_live
          client.setex(path, time_to_live, content)
        else
          client.set(path, content)
        end
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