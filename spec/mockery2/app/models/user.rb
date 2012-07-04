class User < ActiveRecord::Base

  def name
    [self.first_name, self.last_name].compact.join(' ')
  end
end
