# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'activemessaging/processor'
require 'yaml'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  #self.allow_forgery_protection = false

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password
  layout 'default'
  before_filter :set_locale
 
  include ActiveMessaging::MessageSender
  def publish_with_yaml(body, header = {}, timeout = 10)
    yaml_str = YAML.dump(body)
    publish_without_yaml(:ossf_message, yaml_str, header, timeout)
    publish_without_yaml(:joomla_message, yaml_str, header, timeout)
  end
  alias_method_chain :publish, :yaml

  private
  def set_locale  
    @locales = ['English', '繁體中文']
  end

  def login_require
    @user = check_user
    redirect_to login_user_path unless @user
  end
end
