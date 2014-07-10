#------------------------------------------------------------------------------
#
# FundingAmount
#
# Represents the amount of a fund that is available in a fiscal year. Funding amounts
# are initially estimated and the adjusted when the true amount is known.
#
#------------------------------------------------------------------------------
class FundingAmount < ActiveRecord::Base
    
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

  # Has a single funding source
  belongs_to  :funding_source

  # Has 0 or more funding requests
  has_many    :funding_requests
         
  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => :true, :uniqueness => :true
  validates :funding_source_id,                 :presence => :true
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
  
  # Returns the amount of the funding amount that has been requested but not committed to
  def total_requested
    val = 0
    # TODO: filter this amount by requests that have not been committed
    funding_requests.each do |req|
      val += req.amount
    end
    val
  end
  # Returns the amount of the funding amount that has been committed to
  def total_committed
    val = 0
    # TODO: only tally requests that have been committed
    val
  end
  # Returns the amount remaining in this fiscal year. This only
  # takes into account funds that have been committed to as 
  # TAs could allocate funds that will never be committed
  def total_remaining
    # TODO: check to see if this logic is correct   
    amount - total_committed
  end
  
  def name
    "#{funding_source.name}: $#{amount}"
  end
  
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
