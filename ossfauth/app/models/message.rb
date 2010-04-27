class Message < ActiveRecord::Base
  belongs_to :user
  belongs_to :site
  serialize :body

  def clone
    m = Message.new
    %w{action status body user_id site_id}.each{|a|
      m.write_attribute a, self.read_attribute(a)
    }
    m
  end

  named_scope :un_sync, :conditions => {:status => nil}
  named_scope :re_sync, :conditions => {:status => 're_sync'}
end
