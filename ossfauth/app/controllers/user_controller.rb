class UserController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:logout]
  def check_session 
    Session.find_by_session_key(cookies[SITE_SESSION_ID]) || Session.new
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
    #do nothing
  end

  def email
    #do nothing
  end

  def privacy
  end

  def update
    session[:user].update_attributes params['user']
    #flash[:message] = t('Update User Infomation Successfully.')
    redirect_to home_user_path
  end
  
  def home
    @user = check_user
    unless(@user) #force logout, clean cookie
      @user = cookies[SITE_SESSION_ID] = nil
      redirect_to login_user_path
      return
    end 
  end

  def signup
    if request.post?
      u = User.create(:attributes => {
        :name => params[:name],
        :password => params[:password],
        :email => params[:email]
      })
      msg = { 'resource' => 'user', 'action' => 'create', 
            'description' => {:name => u.name, :email => u.email} }
      publish msg
      #render :text => "User name: #{u.name}, email: #{u.email}"
      redirect_to login_user_path
    end   
  end

  def login
    redirect_to home_user_path if check_user
      
    if request.post?
      u = User.authenticate(params[:name], params[:password])
      (render :text => 'Login error';return) unless u
      #reset_session
      cookies[:double_check_id] = 'Q_Q'
      s = u.sessions.new
      s.session_key = cookies[SITE_SESSION_ID]
      s.save
      if params[:return_url] and !params[:return_url].empty?
        redirect_to params[:return_url] 
      else
        #render :text => "Welcome, #{u.name}<br/>your sid is: #{s.session_key}"
        redirect_to home_user_path
      end
    end   
  end

  def logout
    if request.post?
      s = Session.find_by_session_key(cookies[SITE_SESSION_ID])
      (render :text => "Session error cookie= #{cookies[SITE_SESSION_ID]}";return) unless s
      cookies.delete(:key => SITE_SESSION_ID)
      begin
        require 'curb'
        c = Curl::Easy.perform "http://140.109.22.15/index.php?option=com_ofsso&controller=sso&task=logout&username=#{s.user.name}"
      end
      s.delete
      if params[:return_url]
        redirect_to params[:return_url] 
      else
        #render :text => "Goodbye"
        redirect_to home_user_path
      end
    end
  end

end
