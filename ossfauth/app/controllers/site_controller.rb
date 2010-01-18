class SiteController < ApplicationController
def regist
  if request.get?
    @site = Site.new
  elsif request.post?
    site = Site.new(:attributes => {
       :name =>params[:name],
       :ip   =>params[:ip]
       })
    site.regist_key = generate_regist_key
    site.save  
    create_session_url = site.urls.new
    create_session_url.content = params[:create_session_url]
    create_session_url.action = 'create'
    create_session_url.save
    destroy_session_url = site.urls.new 
    destroy_session_url.action = 'destroy'
    destroy_session_url.content = params[:destroy_session_url]
    destroy_session_url.save

    render :text => "your key is: #{site.regist_key}"
  end
end
def deregist
  if request.port?
    Site.find_by_regist_key(params[:key]).delete 
  end
end
  private
  def generate_regist_key
    UUID.new.generate
  end
end
