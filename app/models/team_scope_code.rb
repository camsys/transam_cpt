#------------------------------------------------------------------------------
#
# TeamScopeCode
#
# Lookup Table containing TEAM Scope codes. These are used to identify the TEAM scope
# for a project. The code is a 6-character code with the format XXX-YY where
# XXX is the code eg 111 and YY is a sub code eg 00, 10, 20 etc.
#
#------------------------------------------------------------------------------
class TeamScopeCode < ActiveRecord::Base
          
  # default scope
  default_scope { where(:active => true) }
  
  # Each Scope Code is indexed by the TEAM scope category
  belongs_to  :team_scope_category

  def to_s
    code
  end

  def full_name
    #{code} #{name}
  end
end
