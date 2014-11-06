#------------------------------------------------------------------------------
#
# FundingPlan
#
# Associates an Activity Line Item with a funding source and amount. This is used
# to indicate how the transit agency plans to fund an ALI (and thus a CP).
#
#------------------------------------------------------------------------------
class FundingPlan < ActiveRecord::Base
    
  # Include the object key mixin
  include TransamObjectKey
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize                  :set_defaults
            
  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Each funding plan is associated with a single activity line item
  belongs_to  :activity_line_item

  # Each funding plan is associated with a single budget amount ($ from a source in a FY)
  belongs_to  :budget_amount

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :activity_line_item,  :presence => :true
  validates :budget_amount,       :presence => :true
  validates :amount,              :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}, :allow_nil => true

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------

  #------------------------------------------------------------------------------
  # Constants
  #------------------------------------------------------------------------------
  
  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :activity_line_item_id, 
    :budget_amount_id, 
    :amount
  ]
  
  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
    
  def self.allowable_params
    FORM_PARAMS
  end
  
  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------
  
  def to_s
    name
  end   
     
  def name
    "#{budget_amount.funding_source.name} $#{amount}" unless budget_amount.nil?
  end
  
  def federal_percentage
    federal_amount / amount
  end
  
  def federal_amount
    if budget_amount.nil?
      0
    else
      amount - (state_amount + local_amount)
    end
  end
  
  def state_percentage
    state_amount / amount
  end
  def state_amount
    if budget_amount.nil?
      0
    else
      amount * (budget_amount.funding_source.state_match_required.nil? ? 0 : budget_amount.funding_source.state_match_required / 100)
    end    
  end

  def local_percentage
    local_amount / amount
  end

  def local_amount
    if budget_amount.nil?
      0
    else
      amount * (budget_amount.funding_source.local_match_required.nil? ? 0 : budget_amount.funding_source.local_match_required / 100)
    end    
  end
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 

  # Set resonable defaults for a new capital project
  def set_defaults
    self.amount ||= 0
  end    
      
end
