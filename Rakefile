#!/usr/bin/env rake
require "bundler/gem_tasks"

task :default => [:spec2, :spec3]

task :spec3 do
  info(3)
  dir = File.dirname(__FILE__)
  system("cd #{dir} && rvm gemset create mockery3 && rm Gemfile.lock")
  system("cd #{dir} && rvm gemset use mockery3 && (RAILS_VERSION=3 bundle check || RAILS_VERSION=3 bundle install) && RAILS_VERSION=3 bundle exec rspec -d")
end

task :spec2 do
  info(2)
  dir = File.dirname(__FILE__)
  system("cd #{dir} && rvm gemset create mockery2 && rm Gemfile.lock")
  system("cd #{dir} && rvm gemset use mockery2 && (RAILS_VERSION=2 bundle check || RAILS_VERSION=2 bundle install) && RAILS_VERSION=2 bundle exec spec spec/")
 end

def info(v)
  puts "\n"
  puts "#"*50
  puts "Executing suite against rails #{v} project"
  puts "#"*50
  puts "\n"
end