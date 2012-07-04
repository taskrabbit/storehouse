module Storehouse
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)

      path = env['REQUEST_URI']

      store = ::Storehouse.data_store
      cache_text = store && ::Storehouse::Config.consider_caching?(path) ? store.read(path) : nil

      if cache_text
        [200, headers_for(env, cache_text), cache_text]
      else
        @app.call(env)
      end

    ensure
      store.teardown!
    end

    protected

    def headers_for(env, content)
      {
        'Content-type' => 'text/html',
        'Content-Length' => content.length
      }
    end

  end
end