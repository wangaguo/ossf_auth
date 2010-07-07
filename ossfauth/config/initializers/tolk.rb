# config/initializers/tolk.rb
Tolk::ApplicationController.authenticator = proc {
  authenticate_or_request_with_http_basic do |user_name, password|
    user_name == 'translator' && password == 'transpass'
  end
}
