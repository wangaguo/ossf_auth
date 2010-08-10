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

  def breadcrumb
  aa = <<END
    <!--Pathway Start -->
      <div id="rt-breadcrumbs">
          <div class="rt-breadcrumb-surround">

              <a id="breadcrumbs-home" href="http://www.openfoundry.org/"></a>
                  <span class="breadcrumbs pathway">
                      <a class="pathway" href="URL">Level One</a>
                      <span class="no-link">Level Two</span>
                      <span class="no-link">Level Three</span>
                  </span>
          </div>

         <div class="clear"></div>
      </div>
    <!--Pathway END -->
END
  aa
  end
end
