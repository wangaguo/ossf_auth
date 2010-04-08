# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
require 'active_record'
class Sync
  def self.call(env)
    if env["PATH_INFO"] =~ /^\/sso\/sync\.js/
      [200, {"Content-Type" => "text/html"}, [User.all.to_json]]
    else
      [404, {"Content-Type" => "text/html"}, ["Not Found"]]
    end
  end
end
