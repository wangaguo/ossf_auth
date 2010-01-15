# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_contents_session',
  :secret      => 'ad74922f82944b5ac73a5e9e4fd338fe0ae1f6a657744c735d1b05aebeb87e38c00f2ad9792df27b799d057b7c553e75f57994958c85904bc6ef40275d4806ca'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
