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
  s.add_dependency "wicked"
  s.add_dependency 'state_machine'
  
end
