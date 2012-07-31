module Storehouse
  module Adapter
    class Base

      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def teardown!
        # implement if something needs to occur after each request
      end

      def _read(key)
        read(scoped_key(key))
      end

      def _write(key, value, options = {})
        write(scoped_key(key), value, options)
      end

      def _delete(key)
        delete(scoped_key(key))
      end

      def _clear!(pattern = nil)
        pattern ||= Storehouse.config.scope
        clear!(pattern)
      end
      protected

      def read(key)
        nil # implement this method to return content
      end

      def write(key, value, options = {})
        # implement this method to write a value to the cache
      end

      def delete(key)
        write(key, nil) # implement this method to remove a key from the cache
      end

      def clear!(pattern = nil)
        # implement this method to clear the entire cache
      end

      def scoped_key(path)
        [Storehouse.config.scope, path].compact.join('::')
      end

    end
  end
end