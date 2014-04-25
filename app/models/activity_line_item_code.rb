#------------------------------------------------------------------------------
#
# ActivityLineItemCode
#
# Lookup Table containing TEAM ALIs. Each ALI is decomposed into scope, 
# category, and sub_category fields.
#
# Example:
#   scope         = 11
#   category      = 12
#   sub_category  = 01
#
#   is the code for capital requests for funds to purchase replacement 40ft buses (11.12.01)
#
#------------------------------------------------------------------------------
class ActivityLineItemCode < ActiveRecord::Base
        
  # default scope
  default_scope { where(:active => true) }
 
  def to_s
    #{scope}.#{category}.#{sub_category}
  end

end