# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_ossfauth_session',
  :secret      => '00ad74ccbde1e91aefd5b3c396522c2acacef5fea041efa9c2f60f9c73250e1249960e3649a710d4d49218d00448224bd9e4495dc21550a106b092c55c7d472c'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
