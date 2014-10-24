$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "transam_cpt/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "transam_cpt"
  s.version     = TransamCpt::VERSION
  s.authors     = ["Julian Ray"]
  s.email       = ["jray@camsys.com"]
  s.homepage    = "http://www.camsys.com"
  s.summary     = "TransAM Asset Management Platform. Capital Planning Extensions"
  s.description = "TransAM Asset Management Platform. Capital Planning Extensions."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 4.0.9"
  s.add_dependency 'jquery-ui-rails', '~> 4.2.1'
  s.add_dependency "wicked"
  s.add_dependency 'state_machine'
  s.add_dependency 'transam_transit'

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"  
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "cucumber-rails"
  s.add_development_dependency 'thor'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-bundler'
  s.add_development_dependency 'guard-cucumber'
  s.add_development_dependency 'guard-rails'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'growl'
  
end
