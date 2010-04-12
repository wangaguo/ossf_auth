class UserController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:logout]
  before_filter :login_require, :except => [:signup, :login, :forgot_password]

  def check_session 
    sid = cookies[SITE_SESSION_ID]
    if(sid and !sid.empty?)
      s = Session.find_by_session_key(sid, :include => :user) 
    end
    return s || Session.new
  end

  def check_user
    check_session.user || begin
      e = User.authenticate_by_token(params[:t])
      return nil unless e
      e.user.eval e.body
      redirect_to e.action
      e.user
    end
  end
  
  def edit
    #do nothing
  end

  def passwd
    if request.post?
      #match old password
      #return if !old_password_match #and !@user.tags[:forgot_password]
      #@user.tags.delete :forgot_password

      #save password
      #@user.password = params[:user][:password]
      #@user.password_confirmation = params[:user][:password_confirmation]
      #@user.tags[:change_passwd] = true
      @user.update_attributes params[:user]
      @user.change_password = true
      if @user.save #success
        flash[:message] = 'change passwd success!'
        redirect_to home_user_path
      else
        #flash[:error] = 'error'
      end
    end
  end

  def forgot_password
    u = nil
    return if generate_blank
    if params['email'].empty?#==""
      flash.now[:message] = "Please enter your E-Mail."
    elsif User.find_by_email(params['email']).nil?
      flash.now[:message] = "#{params['email']}" + " has not found!"
    else
      u = User.find_by_email(params['email'])
    end

    if u
      begin
#        tk = u.generate_token
        url = "/sso"
        url += "?user=#{u.name}&token=#{tk}"
#        UserNotify.deliver_forgot_password(u, url)
        flash.now[:message] = "user_forgotten_password_emailed"
        unless u?
          redirect_to login_user_path
          return
        end
      rescue
        flash.now[:message] = "user forgotten password email error"
      end
    end
  end

  def email
    #do nothing
  end

  def privacy
  end

  def update
    @u = check_user
    @u.update_attributes params['user']
    #msg = { 'resource' => 'user', 'action' => 'update', 
    #        'description' => @u.changes }
    #publish msg
    @u.save
    flash[:message] = 'Update User Infomation Successfully.'
    redirect_to home_user_path
  end
  
  def home
    @user = check_user
    unless(@user) #force logout, clean cookie
      @user = nil
      #cookies[SITE_SESSION_ID] = nil
      redirect_to login_user_path
      return
    end 
  end

  def signup
    if request.post?
      @user = User.new params[:user]
      if @user.save
        return signup_success
      end
    end
  end
  
  def signup_success
    flash.now[:message] = 'User SignUp Success'
    @user.messages.create :action => 'create'
    @user.events.create :action => home_user_path, :token => @user.generate_token, :body => 
<<BODY
tags[:email_verified] = true
status = 1
save!
BODY
    #********-Mailer by hyder-*******
    url = home_user_url
    UserNotify.deliver_signup(@user, params[:password], url)
    #********-Mailer by hyder-*******
    redirect_to login_user_path
  end

  def login
    #if already login, go home
    (redirect_to home_user_path;return) if check_user
      
    if request.post?
      @u = User.authenticate(params[:name], params[:password])
      #go to success login user handler
      return login_success if @u #and @u.valid?
      #login faild
      flash[:error] = 'user login faild'
    end   
    #regenerate session key which is empty
    reset_session if request.session_options[:id].nil? or request.session_options[:id].empty?
  end

  def login_success
    #TODO: this is debug nop, remove it somedat
    cookies[:double_check_id] = 'Q_Q'
    s = @u.sessions.new
    s.session_key = request.session_options[:id]
    if(s.session_key.nil? || s.session_key.empty?)
      #a fake session, back to login page
      reset_session
      flash.now[:message] = 'session is broken, plz login again'
      redirect_to login_user_path
      return
    end
    s.save
    if params[:return_url] and !params[:return_url].empty?
      redirect_to params[:return_url] 
    else
      if @u.tags[:istatus] == :no
        flash[:message] = "istatus: #{@u.tags[:istatus]}" 
        redirect_to integration_user_path
      else
        flash[:message] = 'user login success'
        redirect_to home_user_path
      end
    end
  end
  private :login_success

  def logout
    if request.post?
      begin
        require 'curb'
        c = Curl::Easy.perform "http://140.109.22.15/index.php?option=com_ofsso&controller=sso&task=logout&username=#{@user.name}"
      end
      reset_session
      if params[:return_url]
        redirect_to params[:return_url] 
      else
        flash.now[:message] = 'user logout success'
        redirect_to login_user_path
      end
    end
  end

  def integration
    @u = check_user 
  end

  def generate_blank
    case request.method
    when :get
      return true
    end
    return false
  end

end
