require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'
require 'timeout'

module Storehouse
  class Store

    def self.get_connection(spec)
      raise "Invalid Storehouse Configuration. Please provide a valid backend" unless backend = spec['backend']
      "::Storehouse::Connections::#{backend.capitalize}".constantize.new(spec['connections'])
    end

    def initialize(spec)
      @spec = spec || {}
      @timeouts = @spec['timeouts'] || {}
    end


    def read(path)
      execute(:read) do
        response = connection_for(path).read(storage_path(path)) || {}
        object = ::Storehouse::Object.new(response)
        object.path = path
        object
      end
    end

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

    def write_object(path, object)
      execute(:write) do
        hash = object.to_h.except(:path)
        connection_for(path).write(storage_path(path), hash) ? object : nil
      end
    end

    def delete(path)
      execute(:delete) do
        response = connection_for(path).delete(storage_path(path)) || {}
        ::Storehouse::Object.new(response)
      end
    end

    def expire(path)
      object = read(path)
      
      return if object.blank?

      unless object.expired?
        object.expires_at = Time.now.to_i
        write_object(path, object)
      end
    end

    def postpone(object)
      if object.expired?
        object.expires_at = Time.now.to_i + 10
        write_object(object.path, object)
      end
      object
    end

    def clear!
      execute(:clear, 60) do
        prefix = storage_path('')
        connection_for.clear!(prefix)
      end
    end

    def clean!
      execute(:clean, 60) do
        prefix = storage_path('')
        connection_for.clean!(prefix)
      end
    end


    protected

    def execute(kind, default_timeout = 5)
      timeout = @timeouts[kind] || default_timeout

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

    def storage_path(path)
      [Storehouse.namespace, path].compact.join(':')
    end
  end
end