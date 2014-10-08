#------------------------------------------------------------------------------
#
# Milestone
#
# Represents a milestone that has been reached for an ALI as it is processed through
# the grant system. 
#
#------------------------------------------------------------------------------
class Milestone < ActiveRecord::Base

  # Include the object key mixin
  include TransamObjectKey
      
  # Callbacks
  after_initialize  :set_defaults

  # Associations
  belongs_to :activity_line_item

  belongs_to :milestone_type
  
  validates :object_key,          :presence => true
  validates :milestone_type,      :presence => true  
  validates :milestone_date,      :presence => true  
  #validates :comments,            :presence => true

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :id,
    :object_key,
    :milestone_type_id,
    :milestone_date,
    :comments
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
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  # Set resonable defaults for a new asset event
  def set_defaults

  end    
    
  #------------------------------------------------------------------------------
  #
  # Private Methods
  #
  #------------------------------------------------------------------------------
  private
  
end
