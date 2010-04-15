class Event < ActiveRecord::Base
  belongs_to :user

  #delete the token if used
  def expire!
    token = nil
    save!
  end
end
