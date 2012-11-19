require 'rack'
require 'active_support/core_ext/hash/except'

module Storehouse
  class Middleware

    def initialize(app)
      @app = app
    end


    def call(env)

      return strip_storehouse_headers(@app.call(env)) unless Storehouse.enabled?

      storehouse_response(env) do
        @app.call(env)
      end
    end    

    protected

    def storehouse_response(env)

      path = URI.parse(env['REQUEST_URI']).path
      path = "#{path}.html" unless path =~ /\.[a-z0-9A-Z]+$/

      return yield if ignore?(path, env)

      response  = nil
      store     = true
      object    = Storehouse.read(path)

      if reheating?(env) || object.blank?
        response = yield
      elsif object.expired? && !render_expired?(env)
        Storehouse.postpone(object) if Storehouse.postpone?
        response = yield
      else
        response = object.rack_response
        store = false
      end

      attempt_to_store(path, response) if store
      attempt_to_distribute(path, response)

      response
    end


    def attempt_to_store(path, response)

      status, headers, content = response

      return response unless status.to_s == '200'

      if headers.delete('X-Storehouse').to_i > 0
        expires_at = headers.delete('X-Storehouse-Expires-At')
        content = Rack::Response.new(content).body.first unless content.is_a?(String)
        Storehouse.write(path, status, headers, content, expires_at)
      end

      [status, headers, content]

    end


    def attempt_to_distribute(path, response)

      status, headers, content = response

      if headers['X-Storehouse-Distribute'].to_i > 0 || Storehouse.panic?
        Storehouse.write_file(path, content)
      end

      [status, headers, content]
    end


    def strip_storehouse_headers(response)

      status, headers, content = response

      headers.except!('X-Storehouse', 'X-Storehouse-Expires-At', 'X-Storehouse-Distribute')

      [status, headers, content]
    end


    def ignore?(path, env)
      return true if path =~ /\/assets\//
      return true if !Storehouse.ignore_params? && env['QUERY_STRING'].present? && !reheating?(env)
      false
    end

    def render_expired?(env)
      return false unless regex = ::Storehouse.serve_expired_content_to
      useragent = env['User-Agent']
      useragent && !!(useragent =~ /#{regex}/)
    end

    def reheating?(env)
      exp = reheat_expression
      exp && !!(env['QUERY_STRING'] =~ exp)
    end

    def reheat_expression
      param = ::Storehouse.reheat_param
      return nil unless param

      prefix = Storehouse.ignore_params? ? nil : '^'
      suffix = Storehouse.ignore_params? ? nil : '([^&]+)?$'
      /#{prefix}#{param}#{suffix}/
    end

  end
end