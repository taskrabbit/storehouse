# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_mockery2_session',
  :secret      => '779d2df14f01500909b7d38e86d0127c3268b07c92091de4ce17ff21fd82446143e7d34d6d804b82d11bdbe6c66dbb429e4de162b07656f270eab36c0e2b3c9e'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
