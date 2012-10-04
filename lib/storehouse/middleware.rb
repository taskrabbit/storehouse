module Storehouse
  class Middleware

    def initialize(app)
      @app = app
    end


    def call(env)

      request = env

      expire_nonstop = false
      path = request['REQUEST_URI']

      if should_care_about_request?(request) && ::Storehouse.config.consider_caching?(path)
      
        expire_nonstop = true
        content = ::Storehouse.read(path)

        if content
          write_to_filesystem!(content, path) if can_write_to_filesystem? && ::Storehouse.config.distribute?(path)
          return [200, build_headers(path, content), content]
        end

      end

      @app.call(request)

      
    ensure
      ::Storehouse.expire_nonstop_attempt!(path) if expire_nonstop
      ::Storehouse.teardown!
    end

    

    protected

    def should_care_about_request?(request)
      get_request?(request) && void_of_query_string?(request) && ::Storehouse.config.utilize_middleware?(request)
    end

    # maybe we can use a rack::request eventually.
    # right now these are simple operations.
    def get_request?(request)
      request['REQUEST_METHOD'].to_s.downcase == 'get'
    end

    def void_of_query_string?(request)
      ::Storehouse.config.ignore_query_params     || 
      request['QUERY_STRING'].to_s.length == 0   ||
      !reheating?(request)
    end

    def reheating?(request)
      param_to_look_for = ::Storehouse.config.reheat_parameter
      reheating = param_to_look_for && !!(request['QUERY_STRING'] =~ /^#{param_to_look_for}([^&]+)?$/)
      
      # clear the query string so rails so the app won't think anything is abnormal
      if reheating
        request['QUERY_STRING'] = ''
      end
      reheating
    end

    def build_headers(path, content)
      {
        'Content-Type' => format_from_path(path),
        'Content-Length' => content.length.to_s,
        'Cache-Control' => 'private, max-age=0, must-revalidate'
      }.delete_if{|k,v| v.nil? }
    end

    # improve this.
    def format_from_path(path)
      case path.to_s.split('?').first.split('.')[1].to_s
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

    def write_to_filesystem!(content, path)
      ActionController::Base.cache_page(content, path)
    end

    def can_write_to_filesystem?
      defined?(ActionController::Base) && ActionController::Base.respond_to?(:cache_page)
    end

  end
end