module Storehouse
  class Config

    def self.config_list(*names)
      names.each do |name|
        class_eval <<-EV
          attr_accessor :#{name}
          def #{name}!(*paths)
            self.#{name} ||= []
            self.#{name} |= paths.map{|p| Array(p) }.flatten(1)
          end
        EV
      end
    end


    # the name of the adapter to use
    attr_accessor :adapter

    # the options to pass to the adapter
    attr_accessor :adapter_options

    # should we server cached content when query params are present?
    attr_accessor :ignore_query_params

    # upon caching, should we continue writing files to the filesysytem, even if we're pushing them to storehouse
    attr_accessor :continue_writing_filesystem

    # something that responds to call(). return true if the middleware filter should allow the request through, false otherwise
    attr_accessor :middleware_filter

    # completely disable storehouse
    attr_accessor :disabled

    # the scope of the storage mechanism
    attr_accessor :scope

    # the parameter that's passed when we want to reheat the cache
    attr_accessor :reheat_parameter

    # the thing that is provided with errors when something blows up
    attr_accessor :error_receiver
    

    # these are lists that are evaluated to determine if storehouse should consider caching the supplied path
    config_list :distribute, :except, :only
    alias_method :ignore!, :except!

    # only hook controllers when the app tells us to - page caching would be lost otherwise
    def hook_controllers!
      ActionController::Base.extend Storehouse::Controller
    end

    def disable!
      self.disabled = true
    end

    def enable!
      self.disabled = false
    end

    def report_error(e)
      self.error_receiver.try(:call, e)
      nil
    end

    def adapter=(adap, options = nil)
      if options
        self.adapter_options = options
      else
        Storehouse.reset_data_store!
      end
      @adapter = adap
    end

    def adapter_options=(opts)
      Storehouse.reset_data_store!
      @adapter_options = opts
    end

    def reset!
      self.instance_variables.each do |var|
        self.instance_variable_set(var, nil)
      end
      Storehouse.reset_data_store!
    end

    def distribute?(path)
      return false if self.disabled
      list_match?(self.distribute, path)
    end

    # should the middleware be used based on the the current request (env)
    def utilize_middleware?(env)
      if self.middleware_filter && self.middleware_filter.respond_to?(:call)
        self.middleware_filter.call(env)
      else
        true
      end
    end

    # should storehouse consider caching (or reading the cache) of path
    def consider_caching?(path)
      return false  if self.disabled
      return true   if self.except.blank? && self.only.blank?
      return false  if list_match?(self.except, path)
      return true   if self.only.blank?
      return true   if list_match?(self.only, path)
      false
    end

    protected

    def list_match?(list, path)
      return false if list.blank?
      [*list].each{|e| return true if match?(e, path) }
      false
    end

    def match?(against, path)
      case against
      when String
        path == against
      when Regexp
        path =~ against
      when Array
        match?(against.first, path) ? (against.last.respond_to?(:call) ? against.last.call(path) : !!against) : false
      else
        if against.respond_to?(:call)
          !!against.call(path)
        else
          false
        end
      end
    end

  end
end