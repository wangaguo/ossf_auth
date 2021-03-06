module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name
    
    when /the home\s?page/
      root_path
    when /the user logout page/
      logout_user_path
    when /the user login page/
      login_user_path
    when /the user signup page/
      signup_user_path
    when /the user email page/
      email_user_path
    when /the user home page/
      home_user_path
    when /user forgot_password page/
      forgot_password_user_path
    when /user passwd page/
      passwd_user_path
    when /site regist page/
      '/site/regist'
    when /site deregist page/
      '/site/deregist'
    when /session fetch page/
      '/site/fetch'
    when /of-dashboard page/
      '/of/user/dashboard'
    when /sso-integration page/
      integration_user_path
    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
