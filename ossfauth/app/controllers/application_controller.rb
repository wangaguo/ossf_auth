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
 
  include ActiveMessaging::MessageSender
  def publish_with_yaml(body, header = {}, timeout = 10)
    yaml_str = YAML.dump(body)
    publish_without_yaml(:ossf_message, yaml_str, header, timeout)
    publish_without_yaml(:joomla_message, yaml_str, header, timeout)
  end
  alias_method_chain :publish, :yaml

  private
  def set_locale  
    #what language we support
    @locales = {:en => 'English', :zh_TW => '繁體中文'}
   
    #this is our language selection priority:
    locale = ( params[:lang] || cookies[:lang] || session[:lang] || 
        scan_lang_from_browser || :zh_TW )

    #lang is not supported, use :zh_TW
    locale = :zh_TW unless @locales.has_key? locale.to_sym

    #set lang to session, cookie, and I18n
    I18n.locale = session[:lang] = cookies[:lang] = locale
  end
  
  def scan_lang_from_browser
    ( request.env['HTTP_ACCEPT_LANGUAGE'] || '' ).scan(/^[a-z]{2}/).first
  end

  def login_require
    #the user from session
    @user = check_user 
    #the user form security token
    @event = login_by_token #unless @user
    if @event
      if @event.user == @user 
        redirect_to @event.action
      else
        #session user != token user
        #force session user to logout!
        #redirect to logout, return_url = request.url
        redirect_to :controller => :user, :action => :logout, :return_url => request.url      
      end
      #expire the token
      @event.expire!
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
    @user.instance_eval e.body, __FILE__, __LINE__ 
    return e
  end
end
