ActionController::Base.session = {
  :key         => SITE_SESSION_ID.to_s,
  :secret      => '30d096717228c2c04e0736dd1692a61ac96d9e11f031ddfb1d404d7edfc28ae81a14b9c',
  :namespace   => "ofauth-#{RAILS_ENV}",
  :memcache_server => '127.0.0.1:11211'
}

ActionController::Base.session_store = :mem_cache_store
