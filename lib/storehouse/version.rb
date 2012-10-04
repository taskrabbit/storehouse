module Storehouse
  module VERSION

    MAJOR = 0
    MINOR = 0
    PATCH = 11
    PRE   = nil


    def self.to_s
      [MAJOR, MINOR, PATCH, PRE].compact.join('.')
    end
  end
end
