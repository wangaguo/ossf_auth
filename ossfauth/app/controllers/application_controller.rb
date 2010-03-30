# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'activemessaging/processor'
include ActiveMessaging::MessageSender

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  #self.allow_forgery_protection = false

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password
  layout 'default'
  before_filter :set_locale
 
  require 'yaml'

  private
  def set_locale  
    @locales = ['English', '繁體中文']
    
  end
end
