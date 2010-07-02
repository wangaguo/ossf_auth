class UserController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:logout]
  before_filter :login_require, :except => [:availability, :signup, :login, 
      :forgot_password, :integration_whoswho, :email_collision_whoswho,
      :username_collision_whoswho, :image,
      :integration, :integrate_diff_accounts, :integrate_success]

  def edit
  end

  def passwd
    if request.post?
      #save password
      #@user.update_attributes params[:user].reject{|k,v|
      #              not User.columns_for_change_password.member? k}
      @user.old_password = params[:user][:old_password]
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
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
    email = params['email'] 
    if email.nil? or email.empty?
      flash.now[:message] = t "user.plz_enter_your_email"
    elsif User.normal.find_by_email(email).nil?
      flash.now[:message] = "#{email}" + " has not found!"
    else
      u = User.normal.find_by_email(email)
    end

    if u
      begin
        tk = UUID.new.generate :compact #generate token for mail
        u.events.create! :action => passwd_user_path, :token => tk
        url = "#{request.protocol}#{request.host_with_port}#{root_path}?t=#{tk}"
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
    if params[:user][:new_email].strip != params[:user][:email_confirmation].strip
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
        UserNotify.deliver_change_email(@user, params[:user][:new_email], "http://ssodev.openfoundry.org/sso?t=#{tk}")
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
      User.columns_for_edit.each{|col|
        @user[col] =  params[:user][col] if params[:user][col]
      }
      @user.avatar = params[:user][:avatar] if params[:user][:avatar]
      @user[:timezone] = params[:user][:timezone]
      @user.save
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
    #go to user's 'official' home
    redirect_to '/of/user/dashboard'
  end

  def signup
    #if already login, go home
    (flash[:message] = 'You already login';redirect_to home_user_path;return) if check_user
    if request.get? and params[:wsw] and session[:wsw_profile]
      @user = User.new
      @user.first_name = session[:wsw_profile]["name"]
      @user.last_name = session[:wsw_profile]["name"]
      @user.name = session[:wsw_profile]["username"]
      @user.email = session[:wsw_profile]["email"]
      @user.email_confirmation = session[:wsw_profile]["email"]
    end
    if request.post?
      @user = User.new params[:user]
      @user.status = 0
      @user.change_password = true
      @user.params[:from_wsw] = true if session[:wsw_profile]
      @user.params[:wsw_name] = session[:wsw_profile]["username"] if session[:wsw_profile]
      if (User.normal.find_by_email(@user.email).nil?) && (User.normal.find_by_name(@user.name).nil?)
        if @user.save
          return signup_success
        end
      else
        flash.now[:error] = t 'user.your_username_or_email_cannot_register'
      end
    else
      #session["whoswho"] = nil
    end
  end
  
  def signup_success
    flash[:message] = t 'user.user_signup_success'
    tk = @user.generate_token
    @user.events.create :action => home_user_path, :token => tk, :body => 
'
if self.params[:from_wsw] == true
  require "curb"
  c = Curl::Easy.http_post(
      "http://ssodev.openfoundry.org/index.php?option=com_ofsso&controller=sso&task=integrateuser",
      "u=#{self.params[:wsw_name]}&nu=#{self.name}")
    self.messages.create :action => "create"
end
self.params[:email_verified] = true
self.status = 1
self.params[:istatus] = :yes
self.messages.create :action => "create" unless self.params[:from_wsw]
save!
'
    url = home_user_url
    url += "?t=#{tk}"
    UserNotify.deliver_signup(@user, params[:user][:password], url)
    redirect_to login_user_path
  end

  def login
    #clear cache
    session[:whoswho], session[:wsw_profile], session[:of_profile], session[:login], session[:wswlogin], session[:mail], session[:dupuname], session[:dupemail] = nil
    #if already login, go home
    (redirect_to home_user_path;return) if check_user

    #if integration from wsw and want to integrate openfoundry account
    if params[:wsw]
      flash.now[:error]= "#{t('please_enter_your_OpenFoundry_account')}"
    end

    #for UI adjusting
    @extra_note = 'user/login_note'
    @grid_style = 'rt-grid-5 rt-push-7'
    @square_style = 'square10'  

    if request.post?
      # notice the error when account is not synchronized completely
      if cookies[:sync_error_at_of] == params[:name]
        cookies.delete :sync_error_at_of
        flash.now[:error] = t "sso.of_sync_not_complete"
        return login_user_path
      end

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
          return flash.now[:error] = t('integration.You are not a valid Who\'s Who User')
        end  
        } if params[:whoswho] == "1" 

      #verify sso account
      @u = User.authenticate(params[:name], params[:password])

      if (@u and @u.params[:istatus] != :yes)
        session[:user_to_integrate] = @u
        redirect_to integration_user_path
        return
      end 

      #go to success login user handler
      return login_success if @u 

      #login faild
      flash.now[:error] = t 'user.login_faild'
    end   
    #regenerate session key which is empty
    #reset_session if request.session_options[:id].nil? or request.session_options[:id].empty?
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
    if session[:of_profile] = User.find_by_name(session[:wsw_profile]["username"])
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

    session[:user] = @u
    if params[:return_url] and !params[:return_url].empty? and
    params[:return_url].match /^\//  
      redirect_to params[:return_url] 
    else
      flash.now[:message] = 'user login success'
      redirect_to home_user_path
    end
    #session[:wsw_profile].destroy
  end
  private :login_success

  def logout
    #if request.post?
      begin
        require 'curb'
        c = Curl::Easy.perform "http://#{ UI_SCHEMA_CSS_HOST }/index.php?option=com_ofsso&controller=sso&task=logout&username=#{@user.name}"
      end
      reset_session
      if params[:return_url] and !params[:return_url].empty? and
      params[:return_url].match /^\//  
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
          session[:user_to_integrate].messages.create(:action => 'create')
          # log this process
          h = session[:integration_log] || {}
          h[:of] = session[:user_to_integrate].name
          session[:integration_log] = h
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
                # log this process
                h = session[:integration_log] || {}
                h[:wsw] = params['name']
                h[:of] = session[:user_to_integrate].name
                h[:sso] = :none
                session[:integration_log] = h
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
          session[ :dupemail ] = fetch_userdata_from_whoswho( u.email )
        end

        # check duplicate username
        session[ :dupuname ] = fetch_userdata_from_whoswho( session[ :login ] ) 
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
      @ofudata = User.normal.find( :first, :conditions => { :name => session[ :login ] } )
      @wswudata = fetch_userdata_from_whoswho( params[ :user ] )
      h = session[:integration_log] || {}
      h[:wswudata] = @wswudata
      h[:ofudata] = @ofudata
      session[:integration_log] = h

      # default optional columns of user data
      # NOTE: The keys here are the same to the columns of sso-DB.
      @opt_columns = { :email => [], :first_name => [], :last_name => [] }

      # deploy all optional columns of user data from two sites 
      #
      # 1) E-mail
      #
      if session[ :dupemail ] || ( not User.normal.find( :first, :conditions => { :email => @wswudata[ "email" ] } ).nil? )
        #
        # no choice for email in two conditions
        # 1. email is duplicate
        # 2. the email in WSW has been registered in OF
        #
        @opt_columns.delete :email
      else
        @opt_columns[ :email ] = [ @ofudata[ "email" ], @wswudata[ "email" ] ]
      end

      #
      # 2) First Name & Last Name
      #
      if @ofudata[ "last_name" ] == @wswudata[ "name" ].split( " " )[ 0 ]
        @opt_columns.delete :last_name
      else
        @opt_columns[ :last_name ] = [ @ofudata[ "last_name" ], @wswudata[ "name" ].split( " " )[ 0 ] || "" ]
      end  

      if @ofudata[ "first_name" ] == @wswudata[ "name" ].split( " " )[ 1 ]
        @opt_columns.delete :first_name
      else
        @opt_columns[ :first_name ] = [ @ofudata[ "first_name" ], @wswudata[ "name" ].split( " " )[ 1 ] || "" ]
      end

      # if the data is empty, then the optional column(s) will be cancelled.
      @opt_columns.delete :last_name if @opt_columns[ :last_name ] and @opt_columns[ :last_name ].include?( "" )
      @opt_columns.delete :first_name if @opt_columns[ :first_name ] and @opt_columns[ :first_name ].include?( "" )

      # When data of two sites are concurrent, no choice...
      if @opt_columns.blank?
        require "curb"
        c = Curl::Easy.http_post( "http://ssodev.openfoundry.org/index.php?option=com_ofsso&controller=sso&task=integrateuser",
                                  "u=#{ session[ :wswlogin ] }&nu=#{ session[ :login ] }" )
        return integrate_success if c.body_str == 'true'
        render :text => "Whoswho Error: #{ c.body_str }"
      end
    else
    #
    # integrate the data of user's options to DB
    #

      if request.post? and session[ :login ]
        updatechk = true

        # preserve the attributes needed to update the OF DB, and update it!!
        if ( alterdata = params.delete_if { | k, v | !k.start_with?( "WSW_" ) } ) and ( not alterdata.empty? )
          alterhash = {}

          # remove the prefixes of attributes for corresponding with the columns of WSW DB 
          alterdata.each { | k, v | alterhash[ k.gsub( "WSW_", "" ) ] = v }

          # update data to SSO DB 
          ssouser = User.normal.find( :first, :conditions => { :name => session[ :login ] } )
          begin
            ssouser.update_attributes!( alterhash )
            h = session[:integration_log] || {}
            h[:alterhash] = alterhash
            session[:integration_log] = h
            
          rescue
            updatechk = false
          end
        end
       
        # remove prefix of WSW 
        if updatechk
          require "curb"
          c = Curl::Easy.http_post( "http://ssodev.openfoundry.org/index.php?option=com_ofsso&controller=sso&task=integrateuser", 
                                    "u=#{ session[ :wswlogin ] }&nu=#{ session[ :login ] }" )
          return integrate_success if c.body_str == 'true'
          render :text => "Whoswho Error: #{ c.body_str }"
        else
          render :text => "Database Update Error"
        end
      end
    end
  end

  def integrate_success
    # mark the user integrated
    @u = session[:user_to_integrate]
    @u.params[ :istatus ] = :yes
    @u.save
    # log this integration process into messages
    @u.messages.create(:status => 'integrated', :action => 'log', 
      :body => session[:intgration_log])

    flash[ :message ] = "Congratulation!! Your Account has been integrated."
    login_success
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
