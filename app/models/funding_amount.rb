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
    
  # Each funding source was created and updated by a user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :updator, :class_name => "User", :foreign_key => "updated_by_id"
    
  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => :true, :uniqueness => :true
  validates :funding_source_type_id,            :presence => :true
  validates :created_by_id,                     :presence => :true
  validates :updated_by_id,                     :presence => :true
  validates :fy_year,                           :presence => :true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 2000}
  validates :amount,                            :presence => :true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # default scope
  default_scope { where(:active => true) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :funding_source_type_id, 
    :fy_year,
    :amount,
    :is_actual, 
    :active
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
  
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 

  # Set resonable defaults for a new capital project
  def set_defaults
    self.active ||= true
  end    
      
end
