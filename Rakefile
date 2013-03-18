# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "redis-collections"
  gem.homepage = "http://github.com/evanwhalen/redis-collections"
  gem.license = "MIT"
  gem.summary = %Q{Associate collections of models through redis}
  gem.description = %Q{redis-collections associates collections of models with an object, similar how to redis-objects associates Redis data types with an object.}
  gem.email = "evanwhalendev@gmail.com"
  gem.authors = ["Evan Whalen"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new