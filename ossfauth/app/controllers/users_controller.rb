class UsersController < ApplicationController
  def signup
    if request.post?
      u = User.create(:attributes => {
        :name => params[:name],
        :password => params[:password],
        :email => params[:email]
      })
      render :text => "User name: #{u.name}, email: #{u.email}"
    end   
  end

  def login
    if request.post?
      u = User.authenticate(params[:name], params[:password])
      (render :text => 'Login error';return) unless u
      cookies[:double_check_id] = 'Q_Q'
      s = u.sessions.new
      s.session_key = cookies[:_ossfauth_session]
      s.save
      if params[:return_url]
        redirect_to params[:return_url] 
      else
        render :text => "Welcome, #{u.name}<br/>your sid is: #{s.session_key}"
      end
    end   
  end

  def logout
    if request.post?
      s = Session.find_by_session_key(cookies[:_ossfauth_session])
      (render :text => "Session error cookie= #{cookies[:_ossfauth_session]}";return) unless s
      cookies.delete(:key => '_ossfauth_session')
      begin
        require 'curb'
        c = Curl::Easy.perform "http://140.109.22.15/index.php?option=com_ofsso&controller=sso&task=logout&username=#{s.user.name}"
      end
      s.delete
      if params[:return_url]
        redirect_to params[:return_url] 
      else
        render :text => "Goodbye"
      end
    end
  end

end
