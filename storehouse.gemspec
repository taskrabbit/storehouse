# -*- encoding: utf-8 -*-
require File.expand_path('../lib/storehouse/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mike Nelson"]
  gem.email         = ["mike@mikeonrails.com"]
  gem.description   = %q{Storehouse provides a cache layer that wraps Rails' page caching strategy. It provides a middleware that returns content from a centralized cache store and writes files to your local machine on-demand, allowing distribution to multiple servers.}
  gem.summary       = %q{Storehouse provides a cache layer that wraps Rails' page caching strategy.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "storehouse"
  gem.require_paths = ["lib"]
  gem.version       = Storehouse::VERSION
  
  gem.add_dependency('activesupport', '>=0')
  gem.add_dependency('json')
  gem.add_dependency('rack')
  gem.add_dependency('rake')

  unless ENV['TRAVIS']
    if ENV['RUBY_VERSION'] =~ /1\.9/
      gem.add_development_dependency('debugger')
    else
      gem.add_development_dependency('ruby-debug')
    end
  end
end
