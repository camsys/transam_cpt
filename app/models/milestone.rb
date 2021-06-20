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
  belongs_to :activity_line_item #The old Way
  belongs_to :draft_project_phase #The Scenario Way


  belongs_to :milestone_type
  
  validates :object_key,          :presence => true
  validates :milestone_type,      :presence => true  
  #validates :milestone_date,      :presence => true
  #validates :comments,            :presence => true

  # right now assume seed was loaded in the correct order
  # TODO add sort_order to milestone type
  default_scope { order(:milestone_type_id) }

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
  # Class Scopes
  #
  #------------------------------------------------------------------------------
  scope :required, -> { joins(:milestone_type).where(milestone_types: { required: true }) }
  
  #------------------------------------------------------------------------------
  # DotGrants Export
  #------------------------------------------------------------------------------
  def dotgrants_json
    {
      milestone_date: milestone_date,
      comments: comments,
      milestone_type: milestone_type.try(:dotgrants_json)
    }
  end


  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
    
  def self.allowable_params
    FORM_PARAMS
  end

  def required?
    milestone_type.required
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
