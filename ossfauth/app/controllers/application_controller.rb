# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'activemessaging/processor'
require 'yaml'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  #self.allow_forgery_protection = false

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :old_password, :password_confirmation, 
                           :email, :email_confirmation
  layout 'default'
  before_filter :set_locale
  #before_filter :set_session
 
  include ActiveMessaging::MessageSender
  def publish_with_yaml(body, header = {}, timeout = 10)
    yaml_str = YAML.dump(body)
    publish_without_yaml(:ossf_message, yaml_str, header, timeout)
    publish_without_yaml(:joomla_message, yaml_str, header, timeout)
  end
  alias_method_chain :publish, :yaml

  private
  def set_locale  
    @locales = {:en => 'English', :zh_TW => '繁體中文'}
    locale = ( params[:lang] || cookies[:lang] || session[:lang] || 
        scan_lang_from_browser )
    locale = :en unless @locales.has_key? locale.to_sym
    I18n.locale = locale
    session[:lang] = I18n.locale
  end
  
  def scan_lang_from_browser
    lang = 
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    lang = 'zh_TW' if lang == 'zh'
    lang
  end
  
  def set_session 
    unless session[:z]
      session[:z] = 'z'
      redirect_to "/sso#{request.path}"
      return false
    end
    true
  end

  def login_require
    @user = check_user 
    @event = login_by_token unless @user
    if @event 
      redirect_to @event.action
    else
      redirect_to login_user_path unless @user
    end
  end
  
  def login_by_token
    e = User.authenticate_by_token(params[:t])
    return nil unless e
    @user = e.user
    session[:user] = @user
    s = e.user.sessions.new
    s.session_key = request.session_options[:id]
    s.save!
    #e.user.eval e.body
    #redirect_to e.action
    return e
  end
end
