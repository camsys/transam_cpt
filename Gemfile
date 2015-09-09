source "https://rubygems.org"

# This comment is meaningful to rvm, please do not remove.
#ruby-gemset=transam

# lock to a specific version of Ruby
ruby '2.1.1'

# Declare your gem's dependencies in transam_cpt.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'
gem 'transam_core', :github => 'camsys/transam_core', branch: 'master'
gem 'transam_transit', :github => 'camsys/transam_transit', branch: 'master'
gem 'transam_spatial', :github => 'camsys/transam_spatial', branch: 'master'
gem 'mysql2', '~> 0.3.20' # lock gem for dummy app
