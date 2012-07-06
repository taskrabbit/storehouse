module Storehouse
  class Config

    def self.config_list(*names)
      names.each do |name|
        class_eval <<-EV
          attr_accessor :#{name}
          def #{name}!(*paths)
            self.#{name} ||= []
            self.#{name} |= paths
          end
        EV
      end
    end


    attr_accessor :adapter
    attr_accessor :adapter_options
    attr_accessor :continue_writing_filesystem

    config_list :distribute, :except, :only
    alias_method :ignore!, :except!


    def hook_controllers!
      ActionController::Base.extend Storehouse::Controller
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
      else
        false
      end
    end

  end
end