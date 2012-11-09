module Storehouse
  class Config

    def self.config_list(*names)
      names.each do |name|
        class_eval <<-EV, __FILE__, __LINE__ + 1
          attr_reader :#{name}
          def #{name}(*paths)
            @#{name} ||= []
            @#{name} |= paths
            @#{name}
          end
        EV
      end
    end

    # provides a getter and a setter with the same method
    # config_setting :dog
    #   --> dog 'Husky' :=> 'Husky' (setter)
    #   --> dog :=> 'Husky' (getter)
    def self.config_setting(*names)
      names.each do |name|
        class_eval <<-EV, __FILE__, __LINE__ + 1
          attr_reader :#{name}
          
          def #{name}_with_configuration(value = nil)
            return #{name}_without_configuration if value.nil?
            @#{name} = value
            send("on_#{name}_change", value) if respond_to?("on_#{name}_change")
            value
          end

          alias_method_chain :#{name}, :configuration
          
        EV
      end
    end


    # the name of the adapter to use
    config_setting :adapter

    # the options to pass to the adapter
    config_setting :adapter_options

    # should we server cached content when query params are present?
    config_setting :ignore_query_params

    # upon caching, should we continue writing files to the filesysytem, even if we're pushing them to storehouse
    config_setting :continue_writing_filesystem

    # something that responds to call(). return true if the middleware filter should allow the request through, false otherwise
    config_setting :middleware_filter

    # completely disable storehouse
    config_setting :disabled

    # the scope of the storage mechanism
    config_setting :scope

    # the parameter that's passed when we want to reheat the cache
    config_setting :reheat_parameter

    # the thing that is provided with errors when something blows up
    config_setting :error_receiver

    # the thing that tells storehouse we're in a panic mode
    config_setting :panicer
    

    # these are lists that are evaluated to determine if storehouse should consider caching the supplied path
    config_list :distribute, :except, :only
    alias_method :ignore, :except


    def disable!
      self.disabled true
    end

    def enable!
      self.disabled false
    end

    def report_error(e)
      self.error_receiver.try(:call, e)
      nil
    end

    def panic?(path = nil)
      return self.panicer.call(path) if self.panicer.respond_to?(:call)
      !!self.panicer
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

    def on_adapter_options_change(new_value = nil)
      Storehouse.reset_data_store!
    end

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