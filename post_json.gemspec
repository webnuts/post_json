$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "post_json/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "post_json"
  s.version     = PostJson::VERSION
  s.authors     = ["Jacob Madsen and Martin Thoegersen from Webnuts"]
  s.email       = ["hello@webnuts.com"]
  s.homepage    = "https://github.com/webnuts/post_json"
  s.summary     = "PostgreSQL 9.2+ as a Document database"
  s.description = "Combining features from Ruby, ActiveRecord and PostgreSQL provide a great Document Database"

  s.files = Dir["{lib,spec}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 4.0.0"
  s.add_dependency "uuidtools", "~> 2.1.4"
  s.add_dependency "hashie", "~> 2.0.5"

  s.add_development_dependency "pg"
  s.add_development_dependency 'rspec-rails', '~> 2.0'
end
