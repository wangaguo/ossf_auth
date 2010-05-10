class Url < ActiveRecord::Base
  belongs_to :site
  named_scope :action, lambda { |action|
      { :conditions => { :action => action } }
    }
  
  attr_reader :link
  def link
    "http://#{site.ip}#{content}"
  end

end
