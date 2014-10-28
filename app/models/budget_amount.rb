#------------------------------------------------------------------------------
#
# BudgetAmount
#
# Represents the amount in $ allocated to an agency in a fiscal year by 
# funding source type
#
#------------------------------------------------------------------------------
class BudgetAmount < ActiveRecord::Base
    
  # Include the object key mixin
  include TransamObjectKey
  
  # Include the fiscal year mixin
  include FiscalYear
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize                  :set_defaults

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Every budget record belongs to a transit agency
  belongs_to  :organization 

  # Every budget record belongs to a funding source
  belongs_to  :funding_source 
        
  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => :true, :uniqueness => :true
  validates :organization,                      :presence => :true
  validates :funding_source,                    :presence => :true
  validates :fy_year,                           :presence => :true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => Date.today.year}
  validates :amount,                            :presence => :true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # default scope
  default_scope { order(:fy_year)  }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :id,
    :object_key,
    :organization_id,
    :funding_source_id, 
    :fy_year,
    :amount,
    :estimated
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
  
  # Override the mixin method and delegate to it
  def fiscal_year
    super(fy_year)
  end
  
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 

  # Set resonable defaults for a new capital project
  def set_defaults
    self.estimated ||= true
    self.amount ||= 0
  end    
      
end