#------------------------------------------------------------------------------
#
# Budget
#
# Represents the amount in $ allocated to an agency in a fiscal year by type of fund (fed, state)
#
#------------------------------------------------------------------------------
class Budget < ActiveRecord::Base
    
  # Include the unique key mixin
  include UniqueKey
  # Include the fiscal year mixin
  include FiscalYear

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the object key as the restful parameter. All URLS will be of the form
  # /funding_amount/{object_key}/...
  def to_param
    object_key
  end
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize                  :set_defaults

  # Always generate a unique object key before saving to the database
  before_validation(:on => :create) do
    generate_unique_key(:object_key)
  end
            
  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Every budget record belongs to a transit agency
  belongs_to  :organization 

  # Every budget record belongs to a funding source type
  belongs_to  :funding_source_type 
        
  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => :true, :uniqueness => :true
  validates :organization_id,                   :presence => :true
  validates :funding_source_type_id,            :presence => :true
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
    :funding_source_type_id, 
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
