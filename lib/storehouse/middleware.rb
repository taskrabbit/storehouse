module Storehouse
  class Middleware

    def initialize(app)
      @app = app
    end


    def call(env)

      path = env['REQUEST_URI']
      store = ::Storehouse.data_store

      cache_text = store && ::Storehouse.config.consider_caching?(path) ? store.read(path) : nil

      if cache_text
        write_to_filesystem(cache_text, path) if can_write_to_filesystem? && Storehouse.config.distribute?(path)
        return [200, headers_for(env, cache_text), cache_text]
      end

      @app.call(env)

    ensure
      store.try(:teardown!)
    end

    

    protected

    def headers_for(env, content)
      {
        'Content-Type' => format_from_path(env['REQUEST_URI']),
        'Content-Length' => content.length.to_s,
        'Cache-Control' => 'private, max-age=0, must-revalidate'
      }.delete_if{|k,v| v.nil? }
    end

    def format_from_path(path)
      case path.to_s.split('?').first.split('.').last
      when 'html', 'mobile', ''
        'text/html'
      when 'js', 'json'
        'text/javascript'
      when 'css'
        'text/css'
      else
        nil
      end
    end 

    def write_to_filesystem(content, path)
      ActionController::Base.cache_page(content, path)
    end

    def can_write_to_filesystem?
      defined?(ActionController::Base) && ActionController::Base.respond_to?(:cache_page)
    end

  end
end