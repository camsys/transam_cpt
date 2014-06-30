#------------------------------------------------------------------------------
#
# FundingSourceType
#
# Lookup Table for types of funding sources. Initailly: state/federal.
#
#------------------------------------------------------------------------------
class FundingSourceType < ActiveRecord::Base
        
  # default scope
  default_scope { where(:active => true) }
 
  def to_s
    name
  end

end