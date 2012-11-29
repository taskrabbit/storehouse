require 'fileutils'
require 'yaml'
require 'active_support/core_ext/object/blank'
require 'storehouse/railtie' if defined?(Rails)

module Storehouse

  autoload :VERSION,      'storehouse/version'
  autoload :Config,       'storehouse/config'
  autoload :Middleware,   'storehouse/middleware'
  autoload :Object,       'storehouse/object'
  autoload :Store,        'storehouse/store'

  module Connections
    autoload :Memory,     'storehouse/connections/memory'
    autoload :Redis,      'storehouse/connections/redis'
    autoload :Riak,       'storehouse/connections/riak'
  end

  class << self

    %w(read write delete expire postpone clear! clean!).each do |meth|
      class_eval <<-EV
        def #{meth}(*args)
          return nil unless self.enabled?
          self.store.try(:#{meth}, *args)
        end
      EV
    end

    def store
      @store ||= Store.new(self.spec)
    end

    def spec
      @spec ||= begin
        full_config = YAML.load_file(config_path) || {}
        full_config[app_env] || {}
      end
    end

    def write_file(path, content)
      full_path = cache_path(path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.open(full_path, 'w') do |io|
        io.write(content)
      end
    end

    def enabled?
      !!spec['enabled']
    end

    def namespace
      spec['namespace']
    end

    def postpone?
      !!spec['postpone']
    end

    def panic?
      return false unless !!spec['panic_path']
      File.file?(panic_path)
    end

    def ignore_params?
      !!spec['ignore_params']
    end

    def reheat_param
      spec['reheat_param']
    end

    def serve_expired_content_to
      spec['serve_expired_content_to']
    end

    def panic_path
      File.join(app_root, spec['panic_path'])
    end

    def cache_path(file_path = '')
      file_path = endpoint_path(file_path)
      File.join(app_cache_path, file_path)
    end

    def endpoint_path(path)
      path = "#{path}index.html" if path =~ /\/$/
      path = "#{path}.html"  unless path =~ /\.[a-zA-Z0-9]+$/
      path
    end


    protected

    def app_root
      @app_root ||= begin
        root  ||= ENV['RAILS_ROOT']
        root  ||= Rails.root if defined?(Rails)
        root  ||= ENV['RACK_ROOT']
        root  ||= ENV['STOREHOUSE_ROOT']

        raise "[Storehouse] Please provide a root directory via: RAILS_ROOT, RACK_ROOT, or STOREHOUSE_ROOT" unless root
        root
      end
    end


    def app_env
      @app_env ||= begin
        env ||= ENV['RAILS_ENV']
        env ||= Rails.env if defined?(Rails)
        env ||= ENV['RACK_ENV']
        env ||= ENV['STOREHOUSE_ENV']

        raise "[Storehouse] Please provide an environment: RAILS_ENV, RACK_ENV, or STOREHOUSE_ENV" unless env
        env
      end
    end

    def app_cache_path
      @app_cache_path ||= begin
        base_path   = spec['cache_directory'] 
        base_path ||= (Rails.application.config.action_controller.page_cache_directory rescue nil) if defined?(Rails)
        base_path ||= ENV['STOREHOUSE_CACHE_PATH']
        base_path ||= File.join(app_root, 'public')
      end
    end


    def config_path
      File.join(app_root, 'config', 'storehouse.yml')
    end

  end


end
