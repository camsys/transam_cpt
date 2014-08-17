#------------------------------------------------------------------------------
#
# FundingSourceType
#
# Lookup Table for types of funding sources. Initially: state/federal.
#
#------------------------------------------------------------------------------
class FundingSourceType < ActiveRecord::Base
 
  # Has many funding sources
  has_many    :funding_sources
        
  # default scope
  default_scope { where(:active => true) }
 
  def to_s
    name
  end

end