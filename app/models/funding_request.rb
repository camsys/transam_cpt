#------------------------------------------------------------------------------
#
# FundingRequest
#
# Represents the amount of a fund has been requested by a transit agency to fund
# a capital project wholly or in part 
#
#------------------------------------------------------------------------------
class FundingRequest < ActiveRecord::Base
    
  # Include the unique key mixin
  include UniqueKey

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the object key as the restful parameter. All URLS will be of the form
  # /funding_request/{object_key}/...
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

  # Has a single funding line item which it draws on
  belongs_to  :funding_line_item

  # Has a single activity line item that it applies to
  belongs_to  :activity_line_item
    
  # Each funding request was created and updated by a user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :updator, :class_name => "User", :foreign_key => "updated_by_id"
    
  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => :true, :uniqueness => :true
  validates :funding_amount_id,                 :presence => :true
  validates :activity_line_item_id,             :presence => :true
  validates :amount,                            :presence => :true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}
  validates :created_by_id,                     :presence => :true
  validates :updated_by_id,                     :presence => :true

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :funding_amount_id, 
    :activity_line_item_id, 
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
  
  # Returns the federal match required for this request
  def federal_match
    if federal?
      val = amount
    else
      val = amount * funding_amount.funding_source.federal_match_required / 100.0
    end
    val
  end
  
  # returns the state match required for this request
  def state_match
    if federal?
      val = 0
    else
      val = amount * funding_amount.funding_source.state_match_required / 100.0
    end
    val
  end
  
  # returns the local match required for this request
  def local_match
    if federal?
      val = 0
    else
      val = amount * funding_amount.funding_source.local_match_required / 100.0
    end
    val
  end
  
  # Returns true if this is a federal fund, false otherwise
  def federal?
    return false if funding_amount.nil?
    funding_amount.funding_source.funding_source_type_id == 1  
  end
  
  def name
    "#{funding_amount.funding_source.name}" unless funding_amount.nil?
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
