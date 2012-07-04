require 'dalli'

module Storehouse
  module Adapter
    class Dalli < Base

      def initialize(options = {})
        options.reverse_merge!(:host => 'localhost', :port => '11211')
        super(options)
        connect!
      end

      def connect!
        @client ||= begin
          ::Dalli::Client.new("#{self.options[:host]}:#{self.options[:port]}")
        end
      end

      def disconnect!
        @client.close
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

    end
  end
end