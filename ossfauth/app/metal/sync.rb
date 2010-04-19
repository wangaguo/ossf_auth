# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
require 'rubygems'
require 'active_support'

class Sync
  def self.call(env)
    if env["PATH_INFO"] =~ /^\/sso\/sync\.json/
      if req = Rack::Request.new(env) and req.post? and req.params[ "synctime" ]
        syncuser = User.find( :all, :conditions => [ "updated_at > (?)", Time.at( req.params[ "synctime" ].to_i ) ] )
        [200, {"Content-Type" => "application/json"}, [syncuser.to_json]]
      else
        [200, {"Content-Type" => "application/json"}, [Array.new.to_json]]
      end
    else
      [404, {"Content-Type" => "text/html"}, ["Not Found"]]
    end
  end
end
