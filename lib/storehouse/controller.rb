module Storehouse
  module Controller

    def self.extended(base)
      base.instance_eval do
        cattr_accessor :storehouse_page_cache_options
        cattr_accessor :storehouse_page_cache_action
      end
    end

    def set_storehouse_caching_options(options = {})
      self.storehouse_page_cache_options = options.slice(:expires_in, :expires_at, :storehouse)
    end

    def caches_page(*actions)
      return unless perform_caching
      options = actions.extract_options!
      
      unless options.blank?
        self.storehouse_page_cache_options ||= {}
        actions.each do |action|
          self.storehouse_page_cache_options[action] = options
        end
      end


      before_filter(:only => actions){|c| c.class.storehouse_page_cache_action = c.action_name.to_sym }
      super(*(actions | [options]))
    end

    def expire_page(path)
      storehouse_benchmark :expire_page, path do
        Storehouse.delete(path)
      end unless Storehouse.config.disabled
      super
    end

    def cache_page(content, path, extension = nil, gzip = nil)
      
      options = self.storehouse_page_cache_action && self.storehouse_page_cache_options.try(:[], self.storehouse_page_cache_action) || {}

      use_cache = (options[:storehouse].nil? || options[:storehouse]) && Storehouse.config.consider_caching?(path)

      if !use_cache || Storehouse.config.continue_writing_filesystem || Storehouse.config.distribute?(path)
        begin
          super
        rescue Exception => e # rails 2 vs rails 3
          if e.message =~ /wrong number of arguments/
            super(content, path)
          else
            raise e
          end
        end
      elsif use_cache
        storehouse_benchmark :write_page, path do
          Storehouse.write(path, content, options)
        end
      end
    
    end

    protected

    def storehouse_benchmark(key, path)
      if respond_to?(:benchmark)
        statement = key == :expire_page ? 'Expired storehouse page' : 'Cached storehouse page'

        benchmark "#{statement}: #{path}" do
          yield
        end
      elsif respond_to?(:instrument_page_cache)
        instrument_page_cache key, path do
          yield
        end
      else
        yield
      end
    end


  end
end