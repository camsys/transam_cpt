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

  s.metadata = { "load_order" => "20" }

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'rails', '~> 5.2.0'

  s.add_dependency 'rails-data-migrations'

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "cucumber-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "codacy-coverage"
  s.add_development_dependency "simplecov"


end
