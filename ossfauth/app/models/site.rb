require 'curb'
class Site < ActiveRecord::Base
  has_many :urls
  has_many :messages
  
  class << Site
    def notify(action, *params)
      urls.each{|url|
        "http://#{ip}#{url.content}#{params}"
      }
    end
  end
end
