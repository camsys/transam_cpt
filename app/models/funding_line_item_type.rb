class FundingLineItemType < ActiveRecord::Base
          
  # default scope
  default_scope { where(:active => true) }

  def to_s
    code
  end
        
end