module Storehouse
  class Config
    attr_accessor :adapter
    attr_accessor :adapter_options
    attr_accessor :except
    attr_accessor :only

    def consider_caching?(path)

      return true unless self.except.present? || self.only.present?
      
      [*self.except].compact.each do |ignore|
        case ignore
        when String
          return false if path == ignore
        when Regexp
          return false if path =~ ignore 
        end          
      end

      return true unless self.only.present?

      [*self.only].compact.each do |only|
        case only
        when String
          return true if path == only
        when Regexp
          return true if path =~ only
        end
      end

      false
    end

  end
end