#------------------------------------------------------------------------------
#
# TeamSubCategory
#
# Lookup Table containing TEAM sub categories. These are used to identify the specific TEAM
# asset category the request applies to such as 30 Ft Bus
#
#------------------------------------------------------------------------------
class TeamSubCategory < ActiveRecord::Base
          
  # default scope
  default_scope { where(:active => true) }
  
  # Each Category is indexed by the TEAM scope code
  belongs_to  :team_category

  def to_s
    "#{team_category}-#{code}"
  end

end
