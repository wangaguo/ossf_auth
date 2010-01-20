class User < ActiveRecord::Base
  has_many :sessions
  def self.authenticate(name, password)
    find_by_name_and_password(name, password)
  end
end
