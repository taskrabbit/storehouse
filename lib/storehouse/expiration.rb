module Storehouse
  module Expiration

    def expire_page(path)
      Storehouse.delete(path)
      super if defined?(super)
    end

  end
end