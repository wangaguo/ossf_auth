class Message < ActiveRecord::Base
  belongs_to :user
  serialize :body
  named_scope :un_sync, :conditions => {:status => nil}
  named_scope :re_sync, :conditions => {:status => 're_sync'}
end
