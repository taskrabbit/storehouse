class User < ActiveRecord::Base
  attr_accessible :first_name, :last_name

  def name
    [self.first_name, self.last_name].compact.join(' ')
  end
end
