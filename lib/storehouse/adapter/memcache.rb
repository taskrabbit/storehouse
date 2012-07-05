require 'memcache'

module Storehouse
  module Adapter
    class Memcache < Base

      def initialize(options = {})
        options.reverse_merge!(:host => 'localhost', :port => '11211')
        super(options)
        connect!
      end

      def connect!
        @client ||= begin
          Memcache.new(:server => self.server)
        end
      end

      def read(key)
        @client.get(key)
      end

      def write(key, content)
        @client.set(key, content)
      end

      def delete(key)
        @client.delete(key)
      end

      protected

      def server
        "#{self.options[:host]}:#{self.options[:port]}"
      end

    end
  end
end