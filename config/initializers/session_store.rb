# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_retcon-web_session',
  :secret      => '277a774d8d4aa64c823d563b256f5c48feb6e3c916203236f7ce97450ab8f1d1a018513a732f91887959647233b1dda534e614254f6c1018bfa7938f4c39b5d8'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
