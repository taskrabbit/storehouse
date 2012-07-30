require 'memcache'

module Storehouse
  module Adapter
    class Memcache < Base

      def initialize(options = {})
        super
        @client_options = options[:client] || {:host => 'localhost', :port => '11211'}
        connect!
      end

      def connect!
        @client ||= begin
          ::Memcache.new(:server => self.server)
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
        @client.delete(path)
      end

      def clear!
        @client.flush_all
      end

      protected

      def server
        "#{@client_options[:host]}:#{@client_options[:port]}"
      end

    end
  end
end