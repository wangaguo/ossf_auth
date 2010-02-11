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
      s = Session.find_by_session_key(cookies[:_ossfauth_session_])
      (render :text => 'Session error';return) unless s
      if params[:return_url]
        redirect_to params[:return_url] 
      else
        render :text => "Goodbye #{s.user.name}"
      end
    end
  end

end
