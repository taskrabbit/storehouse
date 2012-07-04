module Storehouse
  module Controller

    def expire_page(path)
      Storehouse.delete(path)
      super if defined?(super)
    end

    def cache_page(content, path)
      if Storehouse.config.consider_caching?(path)
        Storehouse.write(path, content) 
      elsif defined?(super)
        super
      end
    end

  end
end