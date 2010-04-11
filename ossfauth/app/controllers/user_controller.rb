class UserController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:logout]
  before_filter :login_require, :except => [:signup, :login]

  def check_session 
    sid = cookies[SITE_SESSION_ID]
    if(sid and !sid.empty?)
      s = Session.find_by_session_key(sid) 
    end
    return s || Session.new
  end
  protected :check_session

  def check_user
    check_session.user 
  end
  protected :check_user
  
  def edit
    #do nothing
  end

  def passwd
    if request.post?
      #match old password
      return if !old_password_match and !@user.tags[:forgot_password]
      @user.tags.delete :forgot_password

      #save password
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
      @user.tags[:change_passwd] = true
      if @user.save #success
        flash[:message] = 'change passwd success!'
        redirect_to home_user_path
      else
        flash[:error] = 'error'
      end
    end
  end

  def old_password_match
    if @user.password != User.encrypt(params[:user][:old_password])
      flash[:message] = 'old password error'
    end
  end
  protected :old_password_match

  def forgot
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
      u = User.create!(:attributes => {
        :name => params[:name],
        :password => params[:password],
        :email => params[:email],
        :first_name => 'empty',
        :last_name => 'empty',
        :timezone => 'TW',
        :language => 'zh'
      })
      #msg = { 'resource' => 'user', 'action' => 'create', 
      #      'description' => {:login => u.name, :email => u.email} }
      #publish msg
      #render :text => "User name: #{u.name}, email: #{u.email}"
      u.messages.create :action => 'create', :body => {:login => u.name, :email => u.email}
     #*******-Mailer by hyder-*******
      #@user = User.new
      #url = home_user_url
      #UserNotify.deliver_signup(@user, :password, url)
     #********-Mailer by hyder-*******
      redirect_to login_user_path
    end   
  end

  def login
    #if already login, go home
    (redirect_to home_user_path;return) if check_user
      
    if request.post?
      @u = User.authenticate(params[:name], params[:password])
      #go to success login user handler
      return login_success if @u and @u.valid?
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
end
