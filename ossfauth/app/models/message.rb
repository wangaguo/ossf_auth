require 'curb'
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



  class << self 
    def load_urls
      @urls = Url.action('sync')
    end

    def load_unsync_message_ids
      @mid = Message.un_sync.find( :all, :select => :id)
    end

    def sync!
      load_urls

      Message.un_sync.each{|m|
        rtn = @urls.map{|url|
          c = Curl::Easy.new url.link
          begin
            c.http_post(
             Curl::PostField.content('data', m.user.to_json) ,
             Curl::PostField.content('action', m.action)
            )
          rescue
          end
          case c.body_str
            #sync successfully!
            when '1','true','ok' then
              true
            #sync faild!
            else
              n = m.clone
              n.user_id = nil
              n.site_id = url.site_id
              n.status = 're_sync'
              n.save!
              false
          end
        }
        m.status = ( rtn.inject{|sum, i|sum and i}? 'ok':'error' )
        m.save!
      }
    end
  end
end
