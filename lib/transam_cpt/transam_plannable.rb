module TransamPlannable
  #------------------------------------------------------------------------------
  #
  # Plannable
  #
  # Injects methods and associations for associating transit assets with capital planning
  # activities
  #
  # Model
  #
  #   The following properties are injected into the Asset Model
  #
  #     has_and_belongs_to_many    :activity_line_items,  :foreign_key => 'asset_id'
  #
  #------------------------------------------------------------------------------
  extend ActiveSupport::Concern

  included do

    # ----------------------------------------------------
    # Call Backs
    # ----------------------------------------------------

     # Clean up any HABTM associations before the asset is destroyed
    before_destroy { activity_line_items.clear }

    # ----------------------------------------------------
    # Associations
    # ----------------------------------------------------

    belongs_to  :replacement_status_type

    has_many   :replacement_status_updates, -> {where :asset_event_type_id => ReplacementStatusUpdateEvent.asset_event_type.id }, :class_name => "ReplacementStatusUpdateEvent",  :foreign_key => :asset_id

    # belongs to 0 or 1 activity_line_items
    has_and_belongs_to_many    :activity_line_items,  :foreign_key => 'asset_id'

    scope :in_replacement_cycle, -> { where('replacement_status_type_id IS NULL OR replacement_status_type_id != ?', ReplacementStatusType.find_by(name: 'None').id) }
    scope :replacement_underway, -> { where(replacement_status_type_id: ReplacementStatusType.find_by(name: 'Underway').id) }

    # ----------------------------------------------------
    # Validations
    # ----------------------------------------------------


  end

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  module ClassMethods

  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  def update_methods
    a = []
    a << super
    [:update_replacement_status].each do |method|
      a << method
    end
    a.flatten
  end

  def in_replacement_cycle?
    ReplacementStatusType.where.not(name: 'None').include? replacement_status_type
  end

  def replacement_by_policy?
    replacement_status_type.nil? || replacement_status_type == ReplacementStatusType.find_by(name: 'By Policy')
  end

  def replacement_underway?
    replacement_status_type == ReplacementStatusType.find_by(name: 'Underway')
  end

  def no_replacement?
    replacement_status_type == ReplacementStatusType.find_by(name: 'None')
  end

  def update_replacement_status(save_asset = true)
    Rails.logger.debug "Updating replacement status for asset = #{object_key}"

    # can't do this if it is a new record as none of the IDs would be set
    unless new_record? or disposed?
      if replacement_status_updates.empty?
        self.replacement_status_type = nil
      else
        event = replacement_status_updates.last
        status = event.replacement_status_type
        self.replacement_status_type = status
      end

      # update scheduled year
      if self.replacement_by_policy?
        self.scheduled_replacement_year = self.policy_replacement_year < current_planning_year_year ? current_planning_year_year : self.policy_replacement_year
      elsif self.replacement_underway?
        self.scheduled_replacement_year = replacement_status_updates.last.replacement_year
        self.update_early_replacement_reason("Replacement is Early and Underway.")
      end

      # save changes to this asset
      if save_asset
        save(:validate => false)

        # update asset and cost(s) in project planner
        service = CapitalProjectBuilder.new
        service.update_asset_schedule(self)
      end

    end
  end


  # Returns the list of capital projects that this asset paricitpates in
  def capital_projects

    projects = []
    activity_line_items.each{|x| projects << x.capital_project}
    projects.uniq
    
  end

end
