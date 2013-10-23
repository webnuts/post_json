$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "post_json/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "post_json"
  s.version     = PostJson::VERSION
  s.authors     = ["Jacob Madsen and Martin Thoegersen"]
  s.email       = ["hello@webnuts.com"]
  s.homepage    = "https://github.com/webnuts/post_json"
  s.summary     = "PostgreSQL as Document database"
  s.description = "A Fast and Flexible Document Database by Combining Features of Ruby and PostgreSQL with PLV8"
  s.license     = 'MIT'

  s.files = Dir["{lib,spec}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "POSTGRESQL_INSTALL_README.md"].select{ |p| p.include?("spec/dummy/log") == false }

  s.add_dependency "rails", "~> 4.0.0"
  s.add_dependency "uuidtools", "~> 2.1.4"
  s.add_dependency "hashie", "~> 2.0.5"

  s.add_development_dependency "pg"
  s.add_development_dependency 'rspec-rails', '~> 2.0'
end
