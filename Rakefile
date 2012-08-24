#!/usr/bin/env rake
require "bundler/gem_tasks"

task :default => [:spec3]

task :spec3 do
  info(3)
  dir = File.dirname(__FILE__)
  system("cd #{dir} && rvm gemset create mockery3 && rm Gemfile.lock")
  system("cd #{dir} && rvm gemset use mockery3 && (RAILS_VERSION=3 bundle check || RAILS_VERSION=3 bundle install) && RAILS_VERSION=3 bundle exec rspec -d")
end

def info(v)
  puts "\n"
  puts "#"*50
  puts "Executing suite against rails #{v} project"
  puts "#"*50
  puts "\n"
end