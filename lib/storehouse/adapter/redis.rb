require 'redis'

module Storehouse
  module Adapter
    class Redis < Base

      def initialize(options = {})
        super
        @client_options = options[:client] || {}
        @namespace = options[:namespace] || '_page_cache'
        connect!
      end

      def connect!
        @client ||= begin
          ::Redis.new(@client_options)
        end
      end 

      def read(path)
        @client.get(end_path(path))
      end

      def write(path, content)
        @client.set(end_path(path), content)
      end

      def delete(path)
        @client.del(end_path(path))
      end

      def clear!
        keys = @client.keys("#{@namespace}::*")
        @client.del(*keys)
      end

      protected

      def end_path(path)
        @namespace + '::' + path
      end

    end
  end
end