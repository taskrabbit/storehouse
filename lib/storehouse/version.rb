module Storehouse
  module VERSION

    MAJOR = 0
    MINOR = 1
    PATCH = 6
    PRE   = nil


    def self.to_s
      [MAJOR, MINOR, PATCH, PRE].compact.join('.')
    end
  end
end
