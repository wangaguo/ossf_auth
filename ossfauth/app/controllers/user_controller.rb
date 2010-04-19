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
    check_session.user || session[:user]
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
      @user.update_attributes params[:user]
      @user.change_password = true
      if @user.save #success
        flash[:message] = 'change passwd success!'
        @user.params.delete :forgot_password
        @user.save_without_validation
        redirect_to home_user_path
      else
        flash.now[:error] = 'error'
      end
    end
  end

  def forgot_password
    u = nil
    return if generate_blank
    if params['email'].empty?
      flash.now[:message] = "Please enter your E-Mail."
    elsif User.find_by_email(params['email']).nil?
      flash.now[:message] = "#{params['email']}" + " has not found!"
    else
      u = User.find_by_email(params['email'])
    end

    if u
      begin
        tk = UUID.new.generate :compact #u.generate_token
        u.events.create! :action => passwd_user_path, :token => tk
        url = "http://ssodev.openfoundry.org" + root_path
        url += "?t=#{tk}"
        UserNotify.deliver_forgot_password(u, url)
        flash.now[:message] = "user_forgotten_password_emailed"
        u.params[:forgot_password] = true
        u.save
      rescue
        flash.now[:message] = "user forgotten password email error: #{$!}"
      end
    end
  end

  def email
    return if generate_blank
    @user.new_email = params[:user][:new_email]
    @user.email_confirmation = params[:user][:email_confirmation]
    if params[:user][:new_email] != params[:user][:email_confirmation]
      flash.now[:error] = 'email is different'
      return
    elsif params[:user][:new_email] == @user.email
      flash.now[:message] = 'email not change'
      return
    else
      begin
        tk = UUID.new.generate :compact 
        @user.events.create! :action => home_user_path, :token => tk, :body =>
<<BODY
self.email = "#{params[:user][:new_email]}"
self.params[:change_email] = nil
save!
BODY
        UserNotify.deliver_change_email(@user, "http://ssodev.openfoundry.org/sso?t=#{tk}")
        flash.now[:message] = "user_change_email_msg_send"
        @user.params[:change_email] = true
        @user.save
      rescue
        flash.now[:error] = 'send email error: '+$!      
      end 
    end
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
      @user.status = 0
      @user.change_password = true
      if @user.save
        return signup_success
      end
    end
  end
  
  def signup_success
    flash[:message] = 'User SignUp Success'
    @user.messages.create :action => 'create'
    tk = @user.generate_token
    @user.events.create :action => home_user_path, :token => tk, :body => 
<<BODY
self.params[:email_verified] = true
self.status = 1
save!
BODY
    url = home_user_url
    url += "?t=#{tk}"
    UserNotify.deliver_signup(@user, params[:user][:password], url)
  end

  def login
    #if already login, go home
    (redirect_to home_user_path;return) if check_user
      
    if request.post?
      @u = User.authenticate(params[:name], params[:password])

      #go to success login user handler
      return login_success if @u 

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
    session[:user] = @u
    if params[:return_url] and !params[:return_url].empty?
      redirect_to params[:return_url] 
    else
      if @u.params[:istatus] == :no
        flash[:message] = "istatus: #{@u.params[:istatus]}" 
        redirect_to integration_user_path
      else
        flash[:message] = 'user login success'
        redirect_to home_user_path
      end
    end
  end
  private :login_success

  def logout
    #if request.post?
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
    #end
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
