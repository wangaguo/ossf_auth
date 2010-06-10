# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'activemessaging/processor'
require 'yaml'

class ApplicationController < ActionController::Base
  #####################
  # default settings
  #####################
  helper :all 
  helper_method :check_user
  protect_from_forgery 

  filter_parameter_logging :password, :old_password, :password_confirmation, 
                           :email, :email_confirmation
  layout 'default'
  before_filter :set_locale
 
  rescue_from ActionController::RoutingError, :with => :not_found

  #####################
  # activemessaging
  #####################
  include ActiveMessaging::MessageSender
  def publish_with_yaml(body, header = {}, timeout = 10)
    yaml_str = YAML.dump(body)
    publish_without_yaml(:ossf_message, yaml_str, header, timeout)
    publish_without_yaml(:joomla_message, yaml_str, header, timeout)
  end
  alias_method_chain :publish, :yaml

  private
  #####################
  # error handler
  #####################
  def not_found
    flash[:error] = t 'not_found'
    redirect_to not_found_rescue_path
  end
  #####################
  # locale setting
  #####################
  def set_locale  
    #what language we support
    @locales = {:en => 'English', :zh_TW => '繁體中文'}
   
    #this is our language selection priority:
    locale = ( params[:lang] || cookies[:oflang] || session[:lang] || 
        scan_lang_from_browser || scan_lang_from_user || :zh_TW )
    locale = :zh_TW if locale == ''
    #lang is not supported, use :zh_TW
    locale = :zh_TW unless(@locales.has_key? locale.to_sym) 

    #set lang to session, cookie, and I18n
    I18n.locale = session[:lang] = cookies[:oflang] = locale
  end
  
  def scan_lang_from_browser
    ( request.env['HTTP_ACCEPT_LANGUAGE'] || '' ).scan(/^[a-z]{2}/).first
  end

  def scan_lang_from_user
    session[:user].lang if session[:user] 
  end

  #####################
  # access control
  # (authn, authn by token)
  #####################
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
    @user.instance_eval e.body, __FILE__, __LINE__ if e.body
    return e
  end
  def check_session
    sid = cookies[SITE_SESSION_ID]
    if(sid and !sid.empty?)
      s = Session.find_by_session_key(sid, :include => :user)
    end
    return s || Session.new
  end

  def check_user
    check_session.user || session[:user]
  end
end
