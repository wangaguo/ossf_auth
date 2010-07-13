class UserNotify < ActionMailer::Base

  def setup_email(user)
    @recipients = "#{user.email}"
    @from       = "contact@openfoundry.org"
    @subject    = "[OpenFoundry] "
    @sent_on    = Time.now
  end
 
  def signup(user, password, url=nil)
    setup_email(user)

    # Set Content-Type for Sending mails
    @content_type = "text/html"

    # Email header info
    @subject += "Welcom to OpenFoundry"

    # Email body substitutions
    @body["name"] = "#{user.first_name} " + "#{user.last_name} "
    @body["login"] = "#{user.name}"
    @body["password"] = "#{password}"
    @body["url"] = url || "#{request.protocol}#{request.host_with_port}#{root_path}"
    @body["app_name"] = "OpenFoundry"
  end

  def forgot_password(user, url=nil)
    setup_email(user)

    # Set Content-Type for Sending mails
    @content_type = "text/html"

    # Email header info
    @subject += "Forgotten password notification"

    # Email body substitutions
    @body["name"] = "#{user.first_name} " + "#{user.last_name}"
    @body["login"] = "#{user.name}"
    @body["url"] = url || "#{request.protocol}#{request.host_with_port}#{root_path}"
    @body["app_name"] = "OpenFoundry"
  end

  def change_email(user, new_email, url) 
    setup_email(user)

    @recipients = new_email

    # Set Content-Type for Sending mails
    @content_type = "text/html"

    # Email header info
    @subject += "Changed email notification"

    # Email body substitutions
    @body["url"] = url || "#{request.protocol}#{request.host_with_port}#{root_path}"
    @body["app_name"] = "OpenFoundry"
  end
end
 
