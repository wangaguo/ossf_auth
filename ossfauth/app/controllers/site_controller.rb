class SiteController < ApplicationController
def regist
   site = Site.new(:attributes => {
      :name =>params[:name]
      })
   create_session_url = site.urls.new
   create_session_url.content = params[:create_session_url]
   create_session_url.type = 'create'
   destroy_session_url = site.urls.new 
   destroy_session_url.type = 'destroy'
   destroy_session_url.content = params[:destroy_session_url]
   
   site.save  
end
def deregist
end

end
