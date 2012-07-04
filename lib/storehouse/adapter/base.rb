module Storehouse
  module Adapter
    class Base

      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def connect!
        # implement if you need to configure a connection
      end

      def teardown!
        # implement if something needs to occur after each request
      end

      def disconnect!
        # implement if you need to release the connection
      end

      def read(key)
        nil # implement this method to return content
      end

      def write(key, value)
        # implement this method to write a value to the cache
      end

      def delete(key)
        write(key, nil) # implement this method to remove a key from the cache
      end

    end
  end
end