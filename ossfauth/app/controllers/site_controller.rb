class SiteController < ApplicationController
skip_before_filter :verify_authenticity_token
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
  if request.post?
    s = Site.find_by_regist_key(params[:regist_key]).delete 
    render :text => "site: #{s.name} deregisted"
  end
end
  def fetch
    if request.post?
      (render :text => 'Error, no such session';return) if params[:session_key].empty?
      s = Site.find_by_regist_key(params[:regist_key])
      (render :text => 'Error, no such key';return) unless s
      s = Session.find_by_session_key(params[:session_key])
      (render :text => 'Error, no such session';return) unless s
      render :text => "id: #{s.user.id}, email: #{s.user.email}, name: #{s.user.name}"    
    end
  end
  private
  def generate_regist_key
    UUID.new.generate
  end
end
