#------------------------------------------------------------------------------
#
# FundingLineItem
#
# Represents a line item allocation of a Federal Fund for a transit agency. The
# line item could be applied for but not awarded in which case it will have a 
# temporary FPN assigned
#
#------------------------------------------------------------------------------
class FundingLineItem < ActiveRecord::Base
    
  # Include the unique key mixin
  include UniqueKey
  # Include the fiscal year mixin
  include FiscalYear

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the asset key as the restful parameter. All URLS will be of the form
  # /FundingLineItem/{object_key}/...
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
  # Every funding line item belongs to an organization
  belongs_to  :organization

  # Has a single funding source
  belongs_to  :funding_source

  # Has a single line item type
  belongs_to  :funding_line_item_type

  # Each funding line item was created and updated by a user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :updator, :class_name => "User", :foreign_key => "updated_by_id"

  # Has 0 or more funding requests drawing down on it. These will be removed if the funding line item is removed
  has_many    :funding_requests, :dependent => :destroy

  # Has 0 or more comments. Using a polymorphic association. These will be removed if the funding line item is removed
  has_many    :comments,    :as => :commentable,  :dependent => :destroy

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => true, :uniqueness => true
  validates :organization_id,                   :presence => true
  validates :fy_year,                           :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => Date.today.year}
  validates :funding_source_id,         :presence => true
  validates :funding_line_item_type_id,           :presence => true
  validates :amount,                            :presence => true, :numericality => {:only_integer => :true, :greater_than => 0}
  validates :pcnt_operating_assistance,         :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100}


  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # default scope

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :organization_id,
    :fy_year,
    :funding_source_id,
    :funding_line_item_type_id,
    :federal_project_number, 
    :awarded,
    :amount,
    :pcnt_operating_assistance,
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
    
  # returns the amount of funds already committed
  def committed
    val = 0
    # TODO: filter this amount by requests that have not been committed
    funding_requests.each do |req|
      val += req.amount
    end
    val
  end
  
  # Returns the amount of funds available
  def available
    amount - committed
  end
  
  # Returns the amount that is not earmarked for operating assistance
  def non_operating_funds
    amount - operating_funds
  end
  
  def operating_funds
    
    amount * (pcnt_operating_assistance / 100.0)
   
  end
  
  # Override the mixin method and delegate to it
  def fiscal_year
    super(fy_year)
  end
  
  def to_s
    federal_project_number
  end
  
  def name
    federal_project_number
  end
    
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 

  # Set resonable defaults for a new capital project
  def set_defaults
    self.active ||= true
    self.awarded ||= false
    self.amount ||= 0
    self.pcnt_operating_assistance ||= 0
    
    # Set the fiscal year to the current fiscal year which can be different from
    # the calendar year
    self.fy_year ||= current_fiscal_year_year + 1
    
  end    
      
end
