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


    attr_accessor :adapter
    attr_accessor :adapter_options
    attr_accessor :continue_writing_filesystem
    attr_accessor :disabled
    attr_accessor :scope
    
    config_list :distribute, :except, :only
    alias_method :ignore!, :except!


    def hook_controllers!
      ActionController::Base.extend Storehouse::Controller
    end

    def disable!
      self.disabled = true
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
      self.adapter = nil
      self.adapter_options = nil
      self.except = []
      self.only = []
      self.distribute = []
      Storehouse.reset_data_store!
    end

    def distribute?(path)
      list_match?(self.distribute, path)
    end

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
        false
      end
    end

  end
end