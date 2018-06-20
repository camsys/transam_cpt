module TransamAssetPlannable
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

    has_many   :replacement_status_updates, -> {where :asset_event_type_id => ReplacementStatusUpdateEvent.asset_event_type.id }, :class_name => "ReplacementStatusUpdateEvent",  :foreign_key => :transam_asset_id

    # belongs to 0 or 1 activity_line_items
    has_and_belongs_to_many    :activity_line_items,  :join_table => :activity_line_items_assets, :foreign_key => 'transam_asset_id'

    scope :in_replacement_cycle, -> { where('replacement_status_type_id IS NULL OR replacement_status_type_id != ?', ReplacementStatusType.find_by(name: 'None').id) }
    scope :replacement_by_policy, -> { where('replacement_status_type_id IS NULL OR replacement_status_type_id = ?', ReplacementStatusType.find_by(name: 'By Policy').id) }
    scope :replacement_by_policy_with_pinned, -> { where('replacement_status_type_id IS NULL OR replacement_status_type_id IN (?)', ReplacementStatusType.where(nam: ['By Policy', 'Pinned']).ids) }
    scope :replacement_pinned, -> { where(replacement_status_type_id: ReplacementStatusType.find_by(name: 'Pinned').id) }
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

  def in_replacement_cycle?
    ReplacementStatusType.where.not(name: 'None').include? replacement_status_type
  end

  def replacement_by_policy?
    replacement_status_type.nil? || replacement_status_type == ReplacementStatusType.find_by(name: 'By Policy')
  end

  def replacement_pinned?
    replacement_status_type == ReplacementStatusType.find_by(name: 'Pinned')
  end

  def replacement_underway?
    replacement_status_type == ReplacementStatusType.find_by(name: 'Underway')
  end

  def no_replacement?
    replacement_status_type == ReplacementStatusType.find_by(name: 'None')
  end

  def formatted_early_replacement_reason
    if replacement_underway?
      "Replacement is Early and Underway."
    elsif early_disposition_requests.count > 0
      early_disposition_requests.last.comments
    else
      '(Reason not provided)'
    end
  end

  # Returns the list of capital projects that this asset paricitpates in
  def capital_projects

    projects = []
    activity_line_items.each{|x| projects << x.capital_project}
    projects.uniq
    
  end

end
