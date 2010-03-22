# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  #self.allow_forgery_protection = false

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password
  layout 'default'
  before_filter :set_locale
  private
  def set_locale  
    @locales = [t('en'), t('zh-TW')]
  end
end
