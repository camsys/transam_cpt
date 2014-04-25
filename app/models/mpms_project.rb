#------------------------------------------------------------------------------
#
# MpmsProject
#
# Lookup Table that acts as a placeholder for references to projects in the MPMS system
#
#------------------------------------------------------------------------------
class MpmsProject < ActiveRecord::Base
    
  # default scope
  default_scope { where(:active => true) }

  def to_s
    name
  end
      
end
