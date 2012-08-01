module Storehouse
  module Controller

    def self.extended(base)
      base.instance_eval do
        cattr_accessor :page_cache_options
        cattr_accessor :page_cache_action
      end
    end

    def set_caching_options(options = {})
      self.page_cache_options = options.slice(:expires_in, :expires_at)
    end

    def caches_page(*actions)
      return unless perform_caching
      options = actions.extract_options!
      
      unless options.blank?
        self.page_cache_options ||= {}
        actions.each do |action|
          self.page_cache_options[action] = options
        end
      end


      before_filter(:only => actions){|c| c.class.page_cache_action = c.action_name.to_sym }
      super(*(actions | [options]))
    end

    def expire_page(path)
      benchmark "Expired storehouse page: #{path}" do
        Storehouse.delete(path)
      end
      super
    end

    def cache_page(content, path, extension = nil, gzip = nil)
      
      options = self.page_cache_action && self.page_cache_options.try(:[], self.page_cache_action) || {}

      use_cache = Storehouse.config.consider_caching?(path)

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
        benchmark "Cached storehouse page: #{path}" do
          Storehouse.write(path, content, options)
        end
      end
    
    end


  end
end