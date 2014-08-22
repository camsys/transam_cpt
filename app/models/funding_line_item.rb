#------------------------------------------------------------------------------
#
# FundingLineItem
#
# Represents a line item allocation of a Fund for a transit agency. The
# line item could be applied for but not awarded in which case it will have a 
# temporary project number assigned
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
  belongs_to  :creator, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to  :updator, :class_name => "User", :foreign_key => "updated_by_id"

  # Has 0 or more comments. Using a polymorphic association. These will be removed if the funding line item is removed
  has_many    :comments,    :as => :commentable,  :dependent => :destroy

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => true, :uniqueness => true
  validates :organization_id,                   :presence => true
  validates :fy_year,                           :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 1990}
  validates :funding_source_id,                 :presence => true
  validates :funding_line_item_type_id,         :presence => true
  validates :amount,                            :presence => true, :numericality => {:only_integer => :true, :greater_than => 0}
  validates :spent,                             :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}
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
    :project_number, 
    :awarded,
    :amount,
    :spent,
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
    
  # Generates a cash flow summary for the funding source
  def cash_flow
        
    a = []
    cum_committed = 0
    
    total_amount = amount.nil? ? 0 : amount
    total_spent = spent.nil? ? 0 : spent
    
    (fy_year..last_fiscal_year_year).each do |yr|
      year_committed = 0
      
      #list = line_items.where('fy_year = ?', yr)
      #list.each do |fli|
      #  year_committed += fli.committed
      #end

      cum_committed += year_committed
      
      # Add this years summary to the cumulative amounts
      a << [fiscal_year(yr), total_amount, total_spent, cum_committed]
    end
    a
      
  end
  # Returns the set of funding requests for this funding line item
  def funding_requests
    
    if federal?
      FundingRequest.where('federal_funding_line_item_id = ?', id)
    else
      FundingRequest.where('state_funding_line_item_id = ?', id)
    end
    
  end
  
  # returns the amount of funds committed but not spent
  def committed
    val = 0
    # TODO: filter this amount by requests that have not been committed
    funding_requests.each do |req|
      if federal?
        val += req.federal_amount
      else
        val += req.state_amount
      end
    end
    val
  end
  
  # Returns the amount of funds available
  def available
    [amount - spent - committed, 0].max
  end
  
  # Returns the amount that is not earmarked for operating assistance
  def non_operating_funds
    amount - operating_funds
  end
  
  def operating_funds
    
    amount * (pcnt_operating_assistance / 100.0)
   
  end
  
  # Returns true if the funding line item is associated with a federal fund, false otherwise
  def federal?
    
    if funding_source
      funding_source.federal?
    else
      false
    end
    
  end
  
  
  # Override the mixin method and delegate to it
  def fiscal_year(year = nil)
    if year
      super(year)
    else
      super(fy_year)
    end
  end
  
  def to_s
    name
  end
  
  def name
    project_number.blank? ? 'N/A' : project_number
  end

  def details
    if project_number.blank?
      "#{funding_source} #{fiscal_year} ($#{available})"
    else
      "#{funding_source} #{fiscal_year}: #{project_number} ($#{available})"
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
    self.active ||= true
    self.awarded ||= false
    self.amount ||= 0
    self.spent ||= 0
    self.pcnt_operating_assistance ||= 0
    
    # Set the fiscal year to the current fiscal year which can be different from
    # the calendar year
    self.fy_year ||= current_fiscal_year_year + 1
    
  end    
      
end
