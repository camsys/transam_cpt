#------------------------------------------------------------------------------
#
# ActivityLineItem
#
# Represents a group of self-similar assets that the organization is requesting
# funding for as part of a larger capital project. Each ALI is associated with
# a single TEAM ALI code eg 11.12.01 that indicates the type of activity funding
# is being applied for.
#
#------------------------------------------------------------------------------
class ActivityLineItem < ActiveRecord::Base

  #------------------------------------------------------------------------------
  # Behaviors
  #------------------------------------------------------------------------------
  # Include the object key mixin
  include TransamObjectKey
  # Include the fiscal year mixin
  include FiscalYear
  # Include the numeric sanitizers mixin
  include TransamNumericSanitizers

  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize :set_defaults

  # Clean up any HABTM associations before the ali is destroyed
  before_destroy { assets.clear }

  after_update :after_update_callback

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Every ali belongs to a capital project
  belongs_to  :capital_project

  delegate :organization, :to => :capital_project

  # Every ALI has a single TEAM sub catagory code
  belongs_to  :team_ali_code

  # an ALI can belong to a fuel type
  belongs_to  :fuel_type

  # Has 0 or more assets
  has_and_belongs_to_many    :assets #, :after_add => :after_add_asset_callback, :after_remove => :after_remove_asset_callback

  # Has 0 or more milestones
  has_many    :milestones, :dependent => :destroy

  # Use a nested form to set the milestones
  accepts_nested_attributes_for :milestones, :allow_destroy => true

  # Has 0 or more comments. Using a polynmorphic association
  has_many    :comments,  :as => :commentable

  # Has 0 or more documents. Using a polymorphic association. These will be removed if the project is removed
  has_many    :documents,   :as => :documentable, :dependent => :destroy

  has_many    :tasks,       :as => :taskable,     :dependent => :destroy

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :capital_project,   :presence => true
  validates :name,              :presence => true
  validates :anticipated_cost,  :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}
  validates :team_ali_code,     :presence => true
  validates :fy_year,           :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 1900}

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------

  # Allow selection of active instances
  scope :active, -> { where(:active => true) }
  # set the default scope
  default_scope { order(:capital_project_id, :fy_year, :team_ali_code_id) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :capital_project_id,
    :fy_year,
    :name,
    :team_ali_code_id,
    :anticipated_cost,
    :cost,
    :cost_justification,
    :active,
    :asset_ids => [],
    :milestones_attributes => [Milestone.allowable_params]
  ]

  # List of fields which can be searched using a simple text-based search
  SEARCHABLE_FIELDS = [
    :object_key,
    :name,
    :team_ali_code
  ]

  # SQL clause for cost sum-up
  # this is also used in CapitalProject related cost calculation
  COST_SUM_SQL_CLAUSE = "(CASE WHEN activity_line_items.anticipated_cost > 0 THEN activity_line_items.anticipated_cost ELSE activity_line_items.estimated_cost END)"

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  def self.total_ali_cost 
    self.sum(COST_SUM_CLAUSE)
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # Returns true if the ALI is an SOGR ALI
  def sogr?
    (capital_project.sogr?)
  end
  # Returns true if the ALI is an future projected ALI
  def notional?
    (capital_project.notional?)
  end

  def is_unconstrained_planning_complete
    plan = CapitalPlan.current_plan(capital_project.organization_id)
    fy_year == plan.fy_year and plan.capital_plan_module_completed?(CapitalPlanModuleType.find_by(name: 'Unconstrained Plan').id)
  end

  def to_s
    name
  end

  def category_team_ali_code
    team_ali_code_id.present? ? team_ali_code.parent.code : ''
  end

  # Returns the cost difference between the anticpated cost by the user and the cost estimated
  # by the system
  def cost_difference
    cost - estimated_cost
  end

  def cost
    unless is_cost_estimated?
      anticipated_cost
    else
      estimated_cost
    end
  end

  def cost=(num)
    unless num.blank?
      self[:anticipated_cost] = sanitize_to_int(num)
    end
  end

  def is_cost_estimated?
    ! (anticipated_cost > 0)
  end

  def restore_estimated_cost
    self.anticipated_cost = 0
    self.estimated_cost = total_asset_cost unless estimated_cost && estimated_cost > 0
    save
  end

  # Returns the total replacment or rehabilitation costs of the assets in this ALI
  def total_asset_cost
    val = 0
    if assets.count > 0
      policy = Policy.find_by(organization_id: assets.first.organization_id)

      # this is to calculate the total ALI cost for a rehabilitation ALI
      # right now rehabilitation cost is taken from the policy
      # though a calculator should be used this is a TODO for a later time
      # reference .calculate_estimated_rehabilitation_cost in Asset model for same TODO
      if assets.where('disposition_date IS NOT NULL').count == 0

        if rehabilitation_ali?
          val = PolicyAssetSubtypeRule.find_by(policy_id: policy.id, asset_subtype_id: assets.first.asset_subtype_id).total_rehabilitation_cost * assets.count
        else
          if self.notional?
            asset_policy_analyzer = assets.first.policy_analyzer
            if asset_policy_analyzer.get_replace_asset_subtype_id.present? && asset_policy_analyzer.get_replacement_cost_calculation_type == CostCalculationType.find_by(class_name: 'PurchasePricePlusInterestCalculator')
              policy_replacement_calculator = CostCalculationType.find_by(class_name: 'ReplacementCostPlusInterestCalculator')
            else
              policy_replacement_calculator = assets.first.policy_analyzer.get_replacement_cost_calculation_type
            end
            assets.each do |a|
              cost = replacement_cost(a, policy_replacement_calculator)
              val += cost.to_i
            end
          else
            val = assets.sum(:scheduled_replacement_cost)
          end
        end
      end
    end

    val
  end

  def rehabilitation_cost asset
    if self.notional?
      (asset.calculate_estimated_rehabilitation_cost(start_of_fiscal_year(capital_project.fy_year))+0.5).to_i
    elsif asset.scheduled_rehabilitation_cost.blank?
      (asset.calculate_estimated_rehabilitation_cost(start_of_fiscal_year(capital_project.fy_year))+0.5).to_i
    else
      asset.scheduled_rehabilitation_cost
    end
  end

  def replacement_cost asset, replacement_cost_calculation_type=nil

    if replacement_cost_calculation_type.nil?
      analyzer = asset.policy_analyzer
      replacement_cost_calculation_type = analyzer.get_replacement_cost_calculation_type
    end

    if self.notional?
      calculate_estimated_replacement_cost(asset, replacement_cost_calculation_type, start_of_fiscal_year(capital_project.fy_year))
    else
      asset.scheduled_replacement_cost
    end
  end

  # Returns true if this is a rehabilitation ALI
  def rehabilitation_ali?
    team_ali_code.rehabilitation_code?
  end

  # Return the organization of the owning object so instances can be index using
  # the keyword indexer
  def organization
    capital_project.organization
  end

  # Update the estimated cost of the ALI based on the assets
  # Add and remove asset are handled in separate callbacks.
  # This should be called when:
  # * When Capital Project changes
  # * When fiscal year changes
  # 
  def update_estimated_cost
    self.estimated_cost = total_asset_cost
    save
  end

  def searchable_fields
    SEARCHABLE_FIELDS
  end

  # check if has any assets that in early replacement
  def has_early_replacement_assets?
    sogr? && !notional? && !assets.early_replacement.empty?
  end

  def has_rehabilitated_assets?
    AssetEvent.where(asset_id: assets.ids, asset_event_type_id: AssetEventType.find_by(class_name: "RehabilitationUpdateEvent").id).count > 0
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  def calculate_estimated_replacement_cost(asset,replacement_cost_calculation_type,on_date=nil)

    return if asset.disposed?

    # Make sure we are working with a concrete asset class
    typed_asset = asset.is_typed? ? asset : Asset.get_typed_asset(asset)

    # create an instance of the calculator class and call the method
    calculator_instance = replacement_cost_calculation_type.class_name.constantize.new
    (calculator_instance.calculate_on_date(typed_asset, on_date)+0.5).to_i #round

  end

  # Callback to update the estimated costs when another asset is added
  def after_add_asset_callback(asset)
    # Check to see if this is rehab or replacement ALI
    if rehabilitation_ali?
      self.estimated_cost += asset.policy_analyzer.get_total_rehabilitation_cost
    else
      self.estimated_cost += replacement_cost(asset) unless asset.scheduled_replacement_cost.nil?
    end
    save
  end

  # Callback to update the estimated costs when an asset is removed
  def after_remove_asset_callback(asset)
    # Check to see if this is rehab or replacement ALI
    if rehabilitation_ali?
      self.estimated_cost -= asset.policy_analyzer.get_total_rehabilitation_cost
    else
      self.estimated_cost -= replacement_cost(asset) unless asset.scheduled_replacement_cost.nil?
    end
    self.estimated_cost = 0 if self.estimated_cost < 0

    save
  end

  def after_update_callback
    # Use update_columns to prevent recursive callbacks
    update_columns(estimated_cost: total_asset_cost) if self.capital_project_id_changed? || self.fy_year_changed?
  end
  
  # Set resonable defaults for a new activity line item
  def set_defaults
    self.active = self.active.nil? ? true : self.active
    self.estimated_cost ||= 0
    self.anticipated_cost ||= 0
  end

end
