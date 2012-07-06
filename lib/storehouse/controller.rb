module Storehouse
  module Controller

    def expire_page(path)
      Storehouse.delete(path)
      super if defined?(super)
    end

    def cache_page(content, path, extension = nil, gzip = nil)
      
      use_cache = Storehouse.config.consider_caching?(path)
      Storehouse.write(path, content) if use_cache
      
      return unless defined?(super)

      if !use_cache || Storehouse.config.continue_writing_filesystem || Storehouse.config.distribute?(path)
        begin
          super
        rescue Exception => e
          if e.message =~ /wrong number of arguments/
            super(content, path)
          else
            raise e
          end
        end
      end
    
    end

  end
end