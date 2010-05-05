class UserController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:logout]
  before_filter :login_require, :except => [:availability, :signup, :login, :forgot_password, :integration_whoswho, :email_collision_whoswho, :username_collision_whoswho, :image]

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
    render @render_options if params[:embedded]
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
      flash.now[:message] = t "user.plz_enter_your_email"
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
        flash.now[:message] = t "user.forgotten_password_emailed"
        u.params[:forgot_password] = true
        u.save
      rescue
        flash.now[:message] = "user forgotten password email error: #{$!}"
      end
    end
  end

  def email
    return if generate_blank
    if params[:user][:new_email] != params[:user][:email_confirmation]
      flash.now[:error] = 'email is different'
      return
    elsif params[:user][:new_email].strip == @user.email.strip
      flash.now[:message] = 'email not change'
      return
    else
      begin
        tk = UUID.new.generate :compact 
        @user.events.create! :action => home_user_path, :token => tk, :body =>
<<BODY
self.email = "#{params[:user][:new_email]}"
self.params.delete :change_email
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
    if request.post?
      @user = check_user
      @user.update_attributes params[:user]
      flash[:message] = 'Update User Infomation Successfully.'
      redirect_to home_user_path
    end
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
    if request.get? and params[:wsw] and session[:wsw_profile]
      @user = User.new
      @user.first_name = session[:wsw_profile]["name"]
      @user.last_name = session[:wsw_profile]["name"]
      @user.name = session[:wsw_profile]["username"]
      @user.email = session[:wsw_profile]["email"]
    end
    if request.post?
      @user = User.new params[:user]
      @user.status = 0
      @user.change_password = true
      @user.params[:from_wsw] = true if session[:wsw_profile]
      @user.params[:wsw_name] = session[:wsw_profile]["username"] if session[:wsw_profile]
      if @user.save
        return signup_success
      end
    else
      #session["whoswho"] = nil
    end
  end
  
  def signup_success
    flash[:message] = 'User SignUp Success'
    tk = @user.generate_token
    @user.events.create :action => home_user_path, :token => tk, :body => 
'
if self.params[:from_wsw] == true
  require "curb"
  c = Curl::Easy.http_post(
      "http://ssodev.openfoundry.org/index.php?option=com_ofsso&controller=sso&task=integrateuser",
      "u=#{self.params[:wsw_name]}&nu=#{self.name}")
    self.messages.create :action => "update"
    self.params.delete :from_wsw
    self.params.delete :wsw_name
end
self.params[:email_verified] = true
self.status = 1
save!
'
    url = home_user_url
    url += "?t=#{tk}"
    UserNotify.deliver_signup(@user, params[:user][:password], url)
  end

  def login
    #clear cache
    session[:whoswho], session[:wsw_profile], session[:of_profile] = nil
    #if already login, go home
    (redirect_to home_user_path;return) if check_user
      
    if request.post?
      # keep the login username
      session[ :login ] = params[ :name ]

      #if use whoswho's account
      #  go to whoswho to verify user
      return validate_whoswho_user{ |value|
        if value == 'true'
          session[:whoswho] = params[:name]
          #return redirect_to signup_user_path #go to wsw...
          return redirect_to integration_whoswho_user_path
        else
          return flash.now[:error] = t('You are not a valid Who\'s Who User')
        end  
        } if params[:whoswho] == "1" 

      #verify sso account
      @u = User.authenticate(params[:name], params[:password])

      #go to success login user handler
      return login_success if @u 

      #login faild
      flash.now[:error] = 'user login faild'
    end   
    #regenerate session key which is empty
    reset_session if request.session_options[:id].nil? or request.session_options[:id].empty?
    #render :layout => false if request.xhr?
    render @render_options if params[:embedded]
  end
  
  def validate_whoswho_user
    require 'curb'
    c = Curl::Easy.http_post(
    "http://ssodev.openfoundry.org/index.php?option=com_ofsso&controller=sso&task=verifyuser", 
    "u=#{params[:name]}&p=#{params[:password]}")
    yield c.body_str if block_given?
  end

  #
  # fetch a user's data from WSW according to the username, email...
  #
  def fetch_userdata_from_whoswho( key )
    if not key.nil? 
      # concatenate the post url of WSW api  
      postquery = ( ( key =~ /@/ )? "byemail&e=" : "&u=" ) + key
      postquery = "http://ssodev.openfoundry.org/index.php?option=com_ofsso&controller=sso&task=getuser" + postquery

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

  def integration_whoswho
    session[:wsw_profile] = fetch_userdata_from_whoswho(session[:whoswho])
    session[:wsw_profile]["username"] = session[:wsw_profile]["username"].delete("!") if session[:wsw_profile]["username"].index("!")
    if session[:of_profile] == User.find_by_name(session[:wsw_profile]["username"])
      if session[:wsw_profile]["email"].strip == session[:of_profile]["email"].strip
        redirect_to email_collision_whoswho_user_path
      elsif session[:wsw_profile]["username"].strip == session[:of_profile]["name"].strip
        redirect_to username_collision_whoswho_user_path
      end
    end
  end

  def email_collision_whoswho
    unless session[:wsw_profile]
      redirect_to login_user_path
    end
  end

  def username_collision_whoswho
    unless session[:wsw_profile]
      redirect_to login_user_path
    end
  end

  def login_success
    #TODO: this is debug nop, remove it somedat
    cookies[:double_check_id] = 'Q_Q'
    s = @u.sessions.new
    s.session_key = request.session_options[:id]
    if(s.session_key.nil? || s.session_key.empty?)
      #a fake session, back to login page
      reset_session
      flash[:message] = 'session is broken, plz login again'
      redirect_to login_user_path
      return
    end
    s.save

    if (@u.params[:istatus] != :yes)
      redirect_to integration_user_path
      return
    end 

    session[:user] = @u
    if params[:return_url] and !params[:return_url].empty?
      redirect_to params[:return_url] 
    else
      flash[:message] = 'user login success'
      redirect_to home_user_path
    end
    #session[:wsw_profile].destroy
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
    if request.post?
    #
    # [ WSW Login Check ]
    #

      case params[ :of_itype ]
        when "REG_WHOSWHO"
          # no WSW account ( create a WSW account immediately ) 

          return integrate_success
        when "LOGIN_WHOSWHO"
          # login WSW for integration

          if params[ 'iuser' ][ 'name' ] and params[ 'iuser' ][ 'password' ]
            # keep data for checking WSW status
            params[ 'name' ] = params[ 'iuser' ][ 'name' ]
            params[ 'password' ] = params[ 'iuser' ][ 'password' ]

            # determine the next step according to the WSW account 
            validate_whoswho_user { | wsw_response |
              if wsw_response == "true"
                redirect_to( :action => 'integrate_diff_accounts', :user => params[ :name ] )
              else
                flash.now[ :error ] = "Whoswho Login Error"
              end
            }
          end
      end
    else
    #
    # [ OF Login ]
    #

      if session[ :login ]
        # check duplicate email
        if u = User.find( :first, :conditions => { :name => session[ :login ] } )
            session[ :mail ] = u.email
            session[ :dupemail ] = true if fetch_userdata_from_whoswho( u.email )
        end

        # check duplicate username
        session[ :dupuname ] = true if fetch_userdata_from_whoswho( session[ :login ] ) 
      end
    end
  end

  def integrate_diff_accounts
    if params[ :user ]
    #
    # arrange the different user data of two sites for selection
    #  

      # keep the username of WSW 
      session[ :wswlogin ] = params[ :user ]

      # select user data from two sites 
      @ofudata = User.find( :first, :conditions => { :name => session[ :login ] } )
      @wswudata = fetch_userdata_from_whoswho( params[ :user ] )

      # default optional columns of user data
      # NOTE: The keys here are the same to the columns of sso-DB.
      @opt_columns = { :email => [], :first_name => [], :last_name => [] }

      # deploy all optional columns of user data from two sites 
      #
      # 1) E-mail
      #
      if session[ :dupemail ]
        @opt_columns.delete :email
      else
        @opt_columns[ :email ] = [ @ofudata[ "email" ], @wswudata[ "email" ] ]
      end

      #
      # 2) First Name & Last Name
      #
      if @wswudata[ "name" ] == @ofudata[ "last_name" ] + " " + @ofudata[ "first_name" ]
        @opt_columns.delete :first_name
        @opt_columns.delete :last_name
      else
        @opt_columns[ :last_name ] = [ @ofudata[ "last_name" ], @wswudata[ "name" ].split( " " )[ 0 ] || "" ]
        @opt_columns[ :first_name ] = [ @ofudata[ "first_name" ], @wswudata[ "name" ].split( " " )[ 1 ] || "" ]
      end

      # When data of two sites are concurrent, no choice...
      integrate_success if @opt_columns.blank?   
    else
    #
    # integrate the data of user's options to DB
    #

      if request.post? and session[ :login ]
        # preserve the attributes needed to update the OF DB, and update it!!
        if alterdata = params.delete_if { | k, v | !k.start_with?( "WSW_" ) }
          alterhash = {}

          # remove the prefixes of attributes for corresponding with the columns of WSW DB 
          alterdata.each { | k, v | alterhash[ k.gsub( "WSW_", "" ) ] = v }

          ssouser = User.find( :first, :conditions => { :name => session[ :login ] } )
          ssouser.update_attributes( alterhash )
        end
       
        # remove prefix of WSW 
        require "curb"
        c = Curl::Easy.http_post( "http://ssodev.openfoundry.org/index.php?option=com_ofsso&controller=sso&task=integrateuser", 
                                  "u=#{ session[ :wswlogin ] }&nu=#{ session[ :login ] }" )
        return integrate_success if c.body_str == 'true'
        render :text => "Whoswho Error: #{ c.body_str }"
      end
    end
  end

  def integrate_success
    # mark the user integrated
    @u = check_user 
    @u.params[ :istatus ] = :yes
    @u.save

    flash[ :message ] = "Congratulation!! Your Account has been integrated."
    redirect_to home_user_path
  end
  
  def image
    user = User.find_by_name params[:name]
    size = params[:size]||:original
    size = :original unless [:thumb, :original, :medium].member? size.to_sym

    return render :text => 'not found', :layout => false unless user
    #send_file(image_cache_file, :type => meta, :disposition => "inline")
    image = user.avatar
    send_file "#{RAILS_ROOT}/public#{image.url(size.to_sym, false)}", 
              :type => image.content_type, :disposition => "inline"
  end

  def generate_blank
    case request.method
    when :get
      return true
    end
    return false
  end

end
