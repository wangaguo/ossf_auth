class AccountController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def availability
    #request from AJAX?
    if request.xhr?
      return check_account_name_available if params[:name]
      return check_account_email_available if params[:email]
    end
    render :text => '', :layout => false
  end

  def check_account_name_available
    name = params[:name]
    text_key = 
    if User.normal.exists?(['name = ?', name]) 
      "user.account_name_used"
    elsif %w{admin administrator superuser root openfoundry}.member? name
      "user.account_name_preserved"
    elsif not name.match /^[a-zA-Z][0-9a-zA-Z_]{2,13}$/
      "user.account_name_invaild"
    else
      "user.account_name_ok"
    end

    text = name.empty? ? '' : t(text_key, :name => name) 
    render :text => "$('#name_availability_result').html('#{text}');",
           :layout => false
  end

  def check_account_email_available
    email = params[:email]
    text_key = 
    if User.normal.exists?(['email = ?', email]) 
      "user.account_email_used"
    elsif fetch_userdata_from_whoswho(email)
      "user.account_wsw_email_used"
    elsif not email.match  /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
      "user.account_email_invaild"
    else
      "user.account_email_ok"
    end
    
    text = email.empty? ? '' : t(text_key, :name => email) 
    render :text => "$('#email_availability_result').html('#{text}');",
           :layout => false
  end
end
