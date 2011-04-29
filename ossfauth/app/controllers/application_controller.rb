# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

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
  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalidauthenticitytoken

  #####################
  # activemessaging
  #####################
  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender
  publishes_to :ossf_msg

  private
  #####################
  # error handler
  #####################
  def not_found
    flash.now[:error] = t 'not_found'
    redirect_to not_found_rescue_path
  end
  def invalidauthenticitytoken 
    set_locale
    flash.now[:error] = t 'not_found'
    #redirect_to not_found_rescue_path
    render :file => 'rescue/invalidauthenticitytoken' , :layout => 'default'
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
    begin
      e = User.authenticate_by_token(params[:t])
      return nil unless e
      @user = e.user
      session[:user] = @user
      s = e.user.sessions.new
      s.session_key = request.session_options[:id]
      s.save!
      @user.instance_eval e.body, __FILE__, __LINE__ if e.body
      #force to sync!
      Message.sync!
      return e
    rescue SignUpDuplicationError
      flash[:error] = t 'integration.email_already_use'
      nil
    end
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

  #
  # fetch a user's data from WSW according to the username, email...
  #
  def fetch_userdata_from_whoswho( key )
    if not key.nil? 
      # concatenate the post url of WSW api  
      postquery = ( ( key =~ /@/ )? "byemail&e=" : "&u=" ) + key
      postquery = "#{request.protocol}#{request.host_with_port}/index.php?option=com_ofsso&controller=sso&task=getuser" + postquery

      # obtain the user data from WSW
      require 'curb'
      chk = Curl::Easy.http_post( postquery )
      begin
        return JSON.parse( chk.body_str ) if not chk.body_str =~ /false/
      rescue JSON::ParserError => e
        flash.now[ :error ] = "Integration Error!!"
        return nil
      end
    end
  end

end
