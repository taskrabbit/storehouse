module Storehouse
  module Controller

    def expire_page(path)
      Storehouse.delete(path)
      super if defined?(super)
    end

    def cache_page(content, path)
      use_cache = Storehouse.config.consider_caching?(path)
      Storehouse.write(path, content) if use_cache
      return unless defined?(super)
      super if !use_cache || Storehouse.config.continue_writing_filesystem || Storehouse.config.distribute?(path)
    end

  end
end