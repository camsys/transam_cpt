#
# Schedule Replacement update event. This is event type is required for
# all implementations
#
class ReplacementStatusUpdateEvent < AssetEvent
      
  # Callbacks
  after_initialize :set_defaults
  after_save       :update_asset

  # Associations
  belongs_to  :replacement_status_type

  validates :replacement_status_type,  :presence => true
      
  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  # set the default scope
  default_scope { where(:asset_event_type_id => AssetEventType.find_by_class_name(self.name).id).order(:event_date, :created_at) }
    
  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :replacement_year,
    :replacement_status_type_id
  ]
  
  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
    
  def self.allowable_params
    FORM_PARAMS
  end
    
  #returns the asset event type for this type of event
  def self.asset_event_type
    AssetEventType.find_by_class_name(self.name)
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # usually no conditions on can create but can be overridden by specific asset events
  def can_update?
    asset_event_type.active && transam_asset.replacement_status_type_id != ReplacementStatusType.find_by(name: 'Pinned').id
  end

  # This must be overriden otherwise a stack error will occur  
  def get_update
    "Replacement status: #{replacement_status_type}."
  end
  
  protected

  def update_asset
    Rails.logger.debug "Updating replacement status for asset = #{transam_asset.object_key}"

    if transam_asset.replacement_status_updates.empty?
      transam_asset.replacement_status_type = nil
    else
      event = transam_asset.replacement_status_updates.last
      status = event.replacement_status_type
      transam_asset.replacement_status_type = status
    end

    # update scheduled year
    if transam_asset.replacement_by_policy?
      transam_asset.scheduled_replacement_year = transam_asset.policy_replacement_year < current_planning_year_year ? current_planning_year_year : transam_asset.policy_replacement_year
    elsif transam_asset.replacement_underway?
      transam_asset.scheduled_replacement_year = transam_asset.replacement_status_updates.last.replacement_year
      #transam_asset.update_early_replacement_reason("Replacement is Early and Underway.")
    end

    transam_asset.save(validate: false)
  end

  # Set resonable defaults for a new condition update event
  def set_defaults
    super
    self.replacement_status_type ||= ReplacementStatusType.find_by(:name => "By Policy")
  end    
  
end
