require 'rack'
require 'active_support/core_ext/object/blank'
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

      # reheating occurs when a reheat param is provided.
      # even if an object exists in the cache we still conduct
      # the request and overwrite the previous value.
      elsif reheating?(env)
        strip_reheat_params(env)
        response = yield

      # if the object we got back had no content we don't return an empty response
      elsif object.blank?
        response = yield

      # if the object is received and it is expired but we are ok
      # rendering expired content (crawler)
      elsif object.expired? && !render_expired?(env)
        Storehouse.postpone(object) if Storehouse.postpone?
        response = yield

      # we get to use the cached content!
      else
        response = object.rack_response

        # if we're in panic mode, we want to distribute this content to disk
        observe_panic_mode(response[1])
        store = false
      end

      # we only care to store this if the response was successful
      # we opt out of 201+ since those response codes are generally
      # associated with resource alteration or other optimization strategies.
      if response[0].to_i == 200
        attempt_to_store(path, response) if store
        attempt_to_distribute(path, response)
      end

      # remove the storehouse headers from the actual response
      strip_storehouse_headers(response)
    end


    def attempt_to_store(path, response)

      status, headers, content = response

      expiration = headers['X-Storehouse-Expires-At']

      # if we've been told to cache the content
      if headers['X-Storehouse'].to_i > 0 || expiration.to_i > 0

        # allow distribution if we're panicing
        observe_panic_mode(headers)

        # write the content to our store
        Storehouse.write(path, status, headers_to_store(headers), string_content(content), expiration)
      end

      [status, headers, content]

    end

    
    # if the distribution header is set we write this content to disk
    def attempt_to_distribute(path, response)

      status, headers, content = response

      if headers['X-Storehouse-Distribute'].to_i > 0
        Storehouse.write_file(path, string_content(content))
      end

      [status, headers, content]
    end


    # remove the headers from the response so the end user is never shown any
    # storehouse content.
    def strip_storehouse_headers(response)
      response[1].except!('X-Storehouse-Distribute', 'X-Storehouse', 'X-Storehouse-Expires-At')
      response
    end

    # strips the headers which we've been told to ignore as well as
    # any standard storehouse headers. (distribution headers stay)
    def headers_to_store(headers)
      ignored_headers = headers.except('X-Storehouse', 'X-Storehouse-Expires-At')
      ignored_headers = ignored_headers.except(*Storehouse.ignore_headers)

      ignored_headers
    end

    # removes the reheat parameter from the request
    # so it won't affect future cache hits
    def strip_reheat_params(env)
      return unless param = Storehouse.reheat_param

      query = env['QUERY_STRING']
      query = query.gsub(/#{param}=?([^&]+)?&?/, '')
      env['QUERY_STRING'] = query
    end

    # there are a bunch of reasons we shouldn't cache content...
    # check them all
    def ignore?(path, env)

      # where are we?
      return true if path.blank?

      # correct request http method?
      return true unless ['', 'get'].include?(env['REQUEST_METHOD'].to_s.downcase)

      # subdomain we care about?
      return true if !valid_subdomain?(env)

      # ignore all /asset requests (switch to content/type checks in the response eventually)
      return true if path =~ /\/assets\//

      # ignore if the query string isn't wanted
      return true if !Storehouse.ignore_params? && env['QUERY_STRING'].present? && !reheating?(env)

      false
    end

    # valid subdomains can be provided in the storehouse.yml
    # if none are provided we accept the request
    def valid_subdomain?(env)
      return true if Storehouse.subdomains.length == 0
      regex = /(^|\.)(#{Storehouse.subdomains.join('|')})\./
      !!(env['HTTP_HOST'] =~ regex)
    end

    # we render expired content when we're panicing or the request
    # is from a source which we're ok serving expired content to (bots are good examples)
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

      # construct a regular expresion that matches:
      # "?reheat_param=anything" if Storehouse.ignore_params
      # "?whatever=a&reheat_param=anything" otherwise
      prefix = Storehouse.ignore_params? ? nil : '^'
      suffix = Storehouse.ignore_params? ? nil : '([^&]+)?$'

      /#{prefix}#{param}#{suffix}/
    end

    # if we're panicing we should distribute all responses
    def observe_panic_mode(headers)
      headers['X-Storehouse-Distribute'] = '1' if Storehouse.panic?
    end

    # extract the string content from a rack response
    # rack responses do not necessarily respond to join
    # but they always respond to #each
    def string_content(rack_response)
      full_content = ''
      rack_response.each{|c| full_content << c }
      full_content
    end

  end
end