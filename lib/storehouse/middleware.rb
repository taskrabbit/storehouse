require 'rack'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/except'

module Storehouse
  class Middleware

    STOREHOUSE_HEADERS = %w(X-Storehouse X-Storehouse-Expires-At)

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

      path_string   = env['PATH_INFO']
      path_string ||= env['REQUEST_URI']

      path = URI.parse(path_string).path rescue nil

      return yield if ignore?(path, env)

      response  = nil
      store     = true
      object    = Storehouse.read(path)

      # failure occurred, don't attempt to store because 
      # we don't want to continue hitting a broken store
      if object.nil?
        response = yield
        store = false
      elsif reheating?(env)
        strip_reheat_params(env)
        response = yield
      elsif object.blank?
        response = yield
      elsif object.expired? && !render_expired?(env)
        Storehouse.postpone(object) if Storehouse.postpone?
        response = yield
      else
        response = object.rack_response
        observe_panic_mode(response[1])
        store = false
      end


      if response[0].to_i == 200
        attempt_to_store(path, response) if store
        attempt_to_distribute(path, response)
      end


      strip_storehouse_headers(response)
    end


    def attempt_to_store(path, response)

      status, headers, content = response


      expiration = headers['X-Storehouse-Expires-At']

      if headers['X-Storehouse'].to_i > 0 || expiration.to_i > 0

        observe_panic_mode(headers)

        Storehouse.write(path, status, headers.except(*STOREHOUSE_HEADERS), string_content(content), expiration)
      end

      [status, headers, content]

    end


    def attempt_to_distribute(path, response)

      status, headers, content = response

      if headers['X-Storehouse-Distribute'].to_i > 0 || (headers['X-Storehouse'].to_i > 0 && Storehouse.panic?)
        Storehouse.write_file(path, string_content(content))
      end

      [status, headers, content]
    end


    def strip_storehouse_headers(response)
      response[1].except!('X-Storehouse-Distribute', *STOREHOUSE_HEADERS)
      response
    end

    def strip_reheat_params(env)
      return unless param = Storehouse.reheat_param

      query = env['QUERY_STRING']
      query = query.gsub(/#{param}=?([^&]+)?&?/, '')
      env['QUERY_STRING'] = query
    end


    def ignore?(path, env)
      return true if path.blank?
      return true unless ['', 'get'].include?(env['REQUEST_METHOD'].to_s.downcase)
      return true if path =~ /\/assets\//
      return true if !Storehouse.ignore_params? && env['QUERY_STRING'].present? && !reheating?(env)
      false
    end

    def render_expired?(env)
      return true if Storehouse.panic?
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

    def observe_panic_mode(headers)
      headers['X-Storehouse'] = '1' if Storehouse.panic?
    end

    def string_content(content)
      content = Rack::Response.new(content).body.first unless content.is_a?(String)
      content
    end

  end
end