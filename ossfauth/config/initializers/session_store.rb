# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_ossfauth_session',
  :secret      => '6368683de659130ae1f20f1f007e3d3ea318a57d45167acbe517251b12301478bd7456a2fa0d6d93221b6f5b37db9bdba5836eedc06e1e5ad3f4dcd30bf96a86'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
