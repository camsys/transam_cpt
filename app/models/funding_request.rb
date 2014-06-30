#------------------------------------------------------------------------------
#
# FundingRequest
#
# Represents the amount of a fund has been requested by a transit agency to fund
# wholly or in part an activity line item.
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

  # Has a single funding amount which is draws on
  belongs_to  :funding_amount

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
