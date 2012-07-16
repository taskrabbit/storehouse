module Storehouse

  autoload :VERSION,      'storehouse/version'
  autoload :Config,       'storehouse/config'
  autoload :Middleware,   'storehouse/middleware'
  autoload :Controller,   'storehouse/controller'

  module Adapter
    autoload :Base,       'storehouse/adapter/base'
    autoload :Memcache,   'storehouse/adapter/memcache'
    autoload :Dalli,      'storehouse/adapter/dalli'
    autoload :Riak,       'storehouse/adapter/riak'
    autoload :Redis,      'storehouse/adapter/redis'
    autoload :S3,         'storehouse/adapter/s3'
  end

  class << self

    cattr_accessor :config
    cattr_accessor :store

    delegate :read, :write, :delete, :clear!, :teardown!, :to => :data_store, :allow_nil => true

    def configure
      self.config ||= ::Storehouse::Config.new
      yield self.config if block_given?
      self.config
    end

    def reset_data_store!
      self.store = nil
    end

    def data_store
      self.store ||= begin
        class_name = (self.config.try(:adapter) || 'Base').to_s
        "Storehouse::Adapter::#{class_name}".constantize.new(self.config.try(:adapter_options) || {})
      end
    end
  end

end
