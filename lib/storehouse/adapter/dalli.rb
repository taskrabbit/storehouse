require 'dalli'

module Storehouse
  module Adapter
    class Dalli < ::Storehouse::Adapter::Memcache

      protected

      def client
        @client ||= begin
          ::Dalli::Client.new(self.server)
        end
      end
      
    end
  end
end