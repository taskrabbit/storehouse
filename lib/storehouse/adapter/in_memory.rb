module Storehouse
  module Adapter
    class InMemory < Base

      def initialize(options = {})
        @data = {}
      end

      protected

      def read(key)
        @data[key].try(:[], :data)
      end

      def write(key, value, options = {})
        @data[key] = {
          :data => value,
          :expires_at => expires_at(options).to_i,
          :created_at => Time.now.to_i
        }
        value
      end

      def delete(key)
        @data.delete(key)
      end

      def clear!(pattern = nil)
        @data.keys do |k|
          delete(k) if pattern.nil? || k.to_s =~ pattern
        end
      end

    end
  end
end