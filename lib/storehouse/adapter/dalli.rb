require 'dalli'

module Storehouse
  module Adapter
    class Dalli < ::Storehouse::Adapter::Memcache

      def connect!
        @client ||= begin
          ::Dalli::Client.new(self.server)
        end
      end

      def disconnect!
        @client.close
      end

    end
  end
end