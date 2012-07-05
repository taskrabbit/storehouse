source 'https://rubygems.org'

# Specify your gem's dependencies in storehouse.gemspec
gemspec


group :development, :test do
  gem 'rails', "#{ENV['rails_version_for_test_suite'] || '2.3.14'}"

  gem 'sqlite3'
  gem 'dalli', '~> 1.0.4'
  
  gem 'rspec-rails', "#{ENV['rspec_rails_version_for_test_suite'] || '1.3.4'}"
end