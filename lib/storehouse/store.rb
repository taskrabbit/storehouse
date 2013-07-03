require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/keys'

require 'timeout'

module Storehouse
  class Store

    def self.get_connection(spec)
      raise "Invalid Storehouse Configuration. Please provide a valid backend" unless backend = spec['backend']
      "::Storehouse::Connections::#{backend.capitalize}".constantize.new(spec['connections'])
    end

    def initialize(spec)
      @spec = spec || {}
      @timeouts = (@spec['timeouts'] || {}).stringify_keys
    end


    # get a storehouse object out of the cache
    def read(path)
      execute(:read) do
        response = connection_for(path).read(storage_path(path)) || {}
        object = ::Storehouse::Object.new(response)
        object.path = path
        object
      end
    end


    # write request attributes to the cache store by creating
    # a storehouse object
    def write(path, status, headers, content, expires_at = nil)
      object = ::Storehouse::Object.new(
        :path       => path, 
        :status     => status, 
        :headers    => headers, 
        :content    => content, 
        :expires_at => expires_at.try(:to_i),
        :created_at => Time.now.to_i
      )
      write_object(path, object)
    end


    # write a storehouse object to the cache store
    def write_object(path, object)
      execute(:write) do
        hash = object.to_h.except(:path)
        connection_for(path).write(storage_path(path), hash) ? object : nil
      end
    end


    # remove the content from the cache
    def delete(path)
      execute(:delete) do
        response = connection_for(path).delete(storage_path(path)) || {}
        ::Storehouse::Object.new(response)
      end
    end


    # expire content at a certain path
    # this does not remove the content from the cache
    def expire(path)
      object = read(path)
      
      return object if object.blank? || object.expired?

      object.expires_at = Time.now.to_i
      write_object(path, object)
    end


    # pushes back expiration to 10 seconds from now
    # this is valuable for bypassing avalanches
    # returns the original object 
    def postpone(object)
      if object.expired?
        object.expires_at = Time.now.to_i + 10
        write_object(object.path, object)
      end
      object
    end

    # clears all the content
    def clear!
      execute(:clear, 60) do
        prefix = namespaced_path('')
        connection_for.clear!(prefix)
        true
      end
    end

    # removes all the expired content
    def clean!
      execute(:clean, 60) do
        prefix = namespaced_path('')
        connection_for.clean!(prefix)
        true
      end
    end


    protected


    # execute the block with a timeout based on the type of activity
    def execute(kind, default_timeout = 5)
      timeout = @timeouts[kind.to_s] || default_timeout

      begin 
        Timeout::timeout(timeout) do
          yield
        end
      rescue Exception => e
        Storehouse.report_exception(e) if Storehouse.respond_to?(:report_exception) 
        nil
      end
    end

    # make room for sharding in the future
    def connection_for(path = nil)
      @connection ||= self.class.get_connection(@spec)
    end

    # the storage path of the content with a file extension
    def storage_path(path)
      Storehouse.endpoint_path(namespaced_path(path))
    end

    # the path with the storehouse namespace included
    def namespaced_path(path)
      [Storehouse.namespace, path].compact.join(':')
    end
  end
end