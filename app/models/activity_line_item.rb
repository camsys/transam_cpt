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

  # Include the object key mixin
  include TransamObjectKey
  # Include the fiscal year mixin
  include FiscalYear

  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize :set_defaults

  # Clean up any HABTM associations before the ali is destroyed
  before_destroy { assets.clear }

  #------------------------------------------------------------------------------
  # Transients
  #------------------------------------------------------------------------------
  attr_accessor :category_team_ali_code

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Every ali belongs to a capital project
  belongs_to  :capital_project

  # Every ALI has a single TEAM sub catagory code
  belongs_to  :team_ali_code

  # Has 0 or more assets
  has_and_belongs_to_many    :assets, :after_add => :after_add_asset_callback, :after_remove => :after_remove_asset_callback

  # Has 0 or more milestones
  has_many    :milestones, :dependent => :destroy

  # Use a nested form to set the milestones
  accepts_nested_attributes_for :milestones, :allow_destroy => true

  # Has 0 or more funding plans -- A funding plan identifies the sources and amounts
  # of funds that will be used to fund the ALI
  has_many    :funding_plans,     :dependent => :destroy

  # Has 0 or more funding requests, These will be removed if the project is removed.
  #has_many    :funding_requests,  :dependent => :destroy

  # Has 0 or more comments. Using a polynmorphic association
  has_many    :comments,  :as => :commentable

  # Has 0 or more documents. Using a polymorphic association. These will be removed if the project is removed
  has_many    :documents,   :as => :documentable, :dependent => :destroy

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
    :cost_justification,
    :active,
    :category_team_ali_code,
    :asset_ids => [],
    :milestones_attributes => [Milestone.allowable_params]
  ]

  # List of fields which can be searched using a simple text-based search
  SEARCHABLE_FIELDS = [
    :object_key,
    :name,
    :team_ali_code
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

  def to_s
    name
  end

  # Returns the total amount of funding planned for this ali
  def total_funds
    val = 0
    funding_plans.each {|x| val += x.amount}
    val
  end

  def funds_required
    cost - total_funds
  end

  # Returns the total value of federal funds requested
  def federal_funds
    val = 0
    funding_plans.each {|x| val += x.federal_share}
    val
  end

  # Returns the total value of state funds requested
  def state_funds
    val = 0
    funding_plans.each {|x| val += x.state_share}
    val
  end

  # Returns the total value of local funds requested
  def local_funds
    val = 0
    funding_plans.each {|x| val += x.local_share}
    val
  end
  def federal_percentage
    100.0 * (federal_funds / total_funds) if total_funds.to_i > 0
  end
  def state_percentage
    100.0 * (state_funds / total_funds) if total_funds.to_i > 0
  end
  def local_percentage
    100.0 * (local_funds / total_funds) if total_funds.to_i > 0
  end

  # Returns the cost difference between the anticpated cost by the user and the cost estimated
  # by the system
  def cost_difference
    cost - estimated_cost
  end

  def cost
    if anticipated_cost > 0
      anticipated_cost
    else
      total_asset_cost
    end
  end

  # Returns the total replacment or rehabilitation costs of the assets in this ALI
  def total_asset_cost
    val = 0
    first_date = start_of_fiscal_year(capital_project.fy_year)
    assets.each do |a|
      # Check to see if this is rehab or replacement ALI
      if rehabilitation_ali?
        val += a.scheduled_rehabilitation_cost.present? ? a.scheduled_rehabilitation_cost : a.policy_analyzer.get_total_rehabilitation_cost
      else
        val += a.scheduled_replacement_cost.present? ? a.scheduled_replacement_cost : a.calculate_estimated_replacement_cost(capital_project.fy_year)
      end
    end
    val
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
  def update_estimated_cost
    self.estimated_cost = total_asset_cost
    save
  end

  def searchable_fields
    SEARCHABLE_FIELDS
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  # Callback to update the estimated costs when another asset is added
  def after_add_asset_callback(asset)
    self.estimated_cost += asset.estimated_replacement_cost unless asset.estimated_replacement_cost.nil?
    save
  end

  # Callback to update the estimated costs when an asset is removed
  def after_remove_asset_callback(asset)
    self.estimated_cost -= asset.estimated_replacement_cost unless asset.estimated_replacement_cost.nil?
    save
  end

  # Set resonable defaults for a new activity line item
  def set_defaults
    self.active ||= true
    self.estimated_cost ||= 0
    self.anticipated_cost ||= 0
    self.category_team_ali_code ||= team_ali_code.present? ? team_ali_code.parent.code : ''
    self.fy_year    ||= current_planning_year_year

  end

end
