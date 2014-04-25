#------------------------------------------------------------------------------
#
# Milestone
#
# Represents a milestone that has been reached for an ALI as it is processed through
# the grant system. 
#
#------------------------------------------------------------------------------
class Milestone < ActiveRecord::Base

  # Include the unique key mixin
  include UniqueKey

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the asset key as the restful parameter. All URLS will be of the form
  # /milestone/{object_key}/...
  def to_param
    object_key
  end
      
  # Callbacks
  after_initialize  :set_defaults

  # Always generate a unique asset key before saving to the database
  before_validation(:on => :create) do
    generate_unique_key(:object_key)
  end
            
  # Associations
  belongs_to :milestone_type
  
  # Each milestone was recorded by a user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by_id"

  validates :object_key,          :presence => true
  validates :milestone_type_id,   :presence => true  
  validates :milestone_date,      :presence => true  
  validates :comments,            :presence => true
  validates :created_by_id,       :presence => true

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :milestone_type_id,
    :milestone_date,
    :comments,
    :created_by_id
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
