# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def show_flash
    keys  = [:error, :warning, :notice, :message]
    keys.collect { |key| content_tag(:p, flash[key],
                                     :class => "flash#{key}") if flash[key]
                 }.join
  end
  def display_signup
    ( not @user ) and ( not session[:whoswho] )
  end
end
