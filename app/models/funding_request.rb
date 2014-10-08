#------------------------------------------------------------------------------
#
# FundingRequest
#
# Represents the amount of a fund has been requested by a transit agency to fund
# a capital project wholly or in part 
#
#------------------------------------------------------------------------------
class FundingRequest < ActiveRecord::Base
    
  # Include the object key mixin
  include TransamObjectKey
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize                  :set_defaults
            
  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Has 0 or 1 federal funding line item which it draws on
  belongs_to  :federal_funding_line_item, :class_name => "FundingLineItem", :foreign_key => :federal_funding_line_item_id

  # Has 0 or 1 state funding line item which it draws on
  belongs_to  :state_funding_line_item,   :class_name => "FundingLineItem", :foreign_key => :state_funding_line_item_id

  # Has a single activity line item that it applies to
  belongs_to  :activity_line_item
    
  # Each funding request was created and updated by a user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :updator, :class_name => "User", :foreign_key => "updated_by_id"
    
  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  #validates :federal_funding_line_item_id,      :presence => :true
  #validates :state_funding_line_item_id,        :presence => :true
  validates :activity_line_item,                :presence => :true
  validates :federal_amount,                    :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}, :allow_nil => true
  validates :state_amount,                      :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}, :allow_nil => true
  validates :local_amount,                      :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}, :allow_nil => true
  validates :created_by_id,                     :presence => :true
  validates :updated_by_id,                     :presence => :true

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :federal_funding_line_item_id, 
    :state_funding_line_item_id, 
    :activity_line_item_id, 
    :federal_amount,
    :state_amount,
    :local_amount
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
  
  def total_amount
    federal_amount + state_amount + local_amount
  end
  
  def federal_percentage
    if total_amount > 0
      pcnt = federal_amount / total_amount.to_f * 100.0
    else
      pcnt = 0.0
    end
  end
  def state_percentage
    if total_amount > 0
      pcnt = state_amount / total_amount.to_f * 100.0
    else
      pcnt = 0.0
    end
  end
  def local_percentage
    if total_amount > 0
      pcnt = local_amount / total_amount.to_f * 100.0
    else
      pcnt = 0.0
    end
  end
      
  def name
    "#{federal_funding_line_item.funding_source.name}" unless federal_funding_line_item.nil?
  end
  
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 

  # Set resonable defaults for a new capital project
  def set_defaults
    self.federal_amount ||= 0
    self.state_amount ||= 0
    self.local_amount ||= 0
  end    
      
end
