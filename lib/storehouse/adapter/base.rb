require 'timeout'

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
        with_timeout(:read) do
          read(scoped_key(key))
        end
      end

      def _write(key, value, options = {})
        with_timeout(:write) do
          write(scoped_key(key), value, options)
        end
      end

      def _delete(key)
        with_timeout(:delete) do
          delete(scoped_key(key))
        end
      end

      def _clear!(pattern = nil)
        pattern ||= Storehouse.config.scope ? "#{Storehouse.config.scope}*" : nil
        with_timeout(:clear, 3600) do
          clear!(pattern)
        end
      end

      def _expire_nonstop_attempt!(key)
        with_timeout(:write) do
          expire_nonstop_attempt!(scoped_key(key))
        end
      end

      protected

      def options
        @options ||= {}
      end

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

      def expire_nonstop_attempt!(key)
        # implement if you want to allow nonstop caching
      end

      def scoped_key(path)
        [Storehouse.config.scope, path].compact.join('::')
      end

      def timeout_length(type = :read)
        timeout = self.options[:timeout]
        if timeout.is_a?(Hash)
          timeout = timeout[type]
        end
        timeout
      end

      def with_timeout(type, default = 5)

        Timeout::timeout(timeout_length(type) || default) do 
          yield
        end

      rescue Timeout::Error => e
        Storehouse.config.report_error(e)
        nil  
      end

      def ttl(opts)
        opts[:expires_in]
      end

      def expires_at(opts)
        expiration = ttl(opts)
        expiration = Time.now + expiration if expiration
        expiration ||= opts[:expires_at]
        expiration
      end

    end
  end
end