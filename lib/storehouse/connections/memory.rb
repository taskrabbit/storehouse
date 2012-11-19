# for testing
module Storehouse
  module Connections
    class Memory

      def initialize(spec)
        @spec = spec
        @data = {}
      end

      def read(path)
        @data[path]
      end

      def write(path, hash)
        @data[path] = hash
      end

      def delete(path)
        @data.delete(path)
      end

      def expire(path)
        delete(path)
      end

      def clear!
        @data = {}
      end

    end
  end
end