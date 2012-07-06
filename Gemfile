source 'https://rubygems.org'

# Specify your gem's dependencies in storehouse.gemspec
gemspec

rails_version = ENV['RAILS_VERSION'].to_s || '2'

group :development, :test do
  gem 'rails', (rails_version == '2' ? '2.3.14' : '3.2.6')

  gem 'sqlite3'
  gem 'dalli', '~> 1.0.4'
  gem 'memcache'
    
  gem 'rspec-core' unless  rails_version == '2'
  gem 'rspec-rails', (rails_version == '2' ? '1.3.4' : '2.10.1')
end