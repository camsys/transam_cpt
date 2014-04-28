#------------------------------------------------------------------------------
#
# TeamCategory
#
# Lookup Table containing TEAM categories. These are used to identify the type
# of project such as Exapnsion, Replacement, Rehabilitation, etc. Each TEAM
# catagory is indexed by the Team Scope so an expansion project for a Rail system (12-13.XX)
# would have a different code from a bus expansion project (11-13-XX)
#
#------------------------------------------------------------------------------
class TeamCategory < ActiveRecord::Base
          
  # default scope
  default_scope { where(:active => true) }
  
  # Each Category is indexed by the TEAM scope code
  belongs_to  :team_scope_code

  def to_s
    code
  end

end
