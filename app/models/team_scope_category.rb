#------------------------------------------------------------------------------
#
# TeamScopeCategory
#
# Lookup Table containing TEAM Scope categories. These are used to index TEAM scope codes
# into Capital, Operating, Planning, etc. categories 
#
#------------------------------------------------------------------------------
class TeamScopeCategory < ActiveRecord::Base
          
  # default scope
  default_scope { where(:active => true) }

  # Each TEAM scope category has one or more scope codes
  has_many  :team_scope_codes
  
  def to_s
    name
  end
        
end
