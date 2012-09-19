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
    autoload :InMemory,   'storehouse/adapter/in_memory'
  end

  class << self

    delegate :teardown!, :to => :data_store, :allow_nil => true

    %w(read write delete clear! expire_nonstop_attempt!).each do |meth|
      class_eval <<-EV
        def #{meth}(*args)
          return nil if self.config.disabled
          self.data_store.try(:_#{meth}, *args)
        end
      EV
    end

    def configure(&block)
      if block_given?
        configuration.instance_eval(&block)
      end
      configuration
    end
    alias_method :config, :configure
    
    def reset_data_store!
      @store = nil
    end

    protected

    def configuration
      @configuration ||= ::Storehouse::Config.new
    end

    def data_store
      @store ||= begin
        class_name = (self.config.try(:adapter) || 'Base').to_s
        "Storehouse::Adapter::#{class_name}".constantize.new(self.config.try(:adapter_options) || {})
      end
    end
  end

end
