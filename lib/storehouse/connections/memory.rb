# for testing
module Storehouse
  module Connections
    class Memory

      def initialize(spec)
        @spec = spec
        @data = {}
      end

      def read(path)
        @data[path.to_s]
      end

      def write(path, hash)
        @data[path.to_s] = hash
      end

      def delete(path)
        @data.delete(path.to_s)
      end

      def expire(path)
        delete(path)
      end

      def clear!(namespace = nil)
        @data = {}
      end

    end
  end
end