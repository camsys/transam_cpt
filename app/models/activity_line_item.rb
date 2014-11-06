#------------------------------------------------------------------------------
#
# ActivityLineItem
#
# Represents a group of self-similar assets that the organization is requesting
# funding for as part of a larger capital project. Each ALI is associated with
# a single TEAM ALI code eg 11.12.01 that indicates the type of fundiung being
# applied for.
#
#------------------------------------------------------------------------------
class ActivityLineItem < ActiveRecord::Base

  # Include the object key mixin
  include TransamObjectKey

  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize :set_defaults

  # Clean up any HABTM associations before the ali is destroyed
  before_destroy { assets.clear }

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

  # Has 0 or more funding plans -- these are for planning ALIs only, when an ALI is 
  # programmed these will be removed and replaced by more funding requests
  has_many    :funding_plans,     :dependent => :destroy

  # Has 0 or more funding requests, These will be removed if the project is removed.
  has_many    :funding_requests,  :dependent => :destroy

  # Has 0 or more comments. Using a polynmorphic association
  has_many    :comments,  :as => :commentable

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :capital_project,   :presence => true
  validates :name,              :presence => true
  validates :anticipated_cost,  :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}
  validates :team_ali_code,     :presence => true

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------

  # default scope
  default_scope { where(:active => true) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :capital_project_id,
    :name,
    :team_ali_code_id,
    :anticipated_cost,
    :cost_justification,
    :active,
    :asset_ids => [],
    :milestones_attributes => [Milestone.allowable_params]
    
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
    funding_plans.each do |fp|
      val += fp.federal_amount
    end
    val
  end
  
  # Returns the total value of state funds requested
  def state_funds
    val = 0
    funding_plans.each do |fp|
      val += fp.state_amount
    end
    val
  end
  
  # Returns the total value of local funds requested
  def local_funds
    val = 0
    funding_plans.each do |fp|
      val += fp.local_amount
    end
    val
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
    assets.each do |a|
      # determine which cost to use based on the year of the project
      if a.scheduled_replacement_year == capital_project.fy_year
        val += a.scheduled_replacement_cost unless a.scheduled_replacement_cost.nil?
      else
        val += a.scheduled_rehabilitation_cost unless a.scheduled_rehabilitation_cost.nil?
      end
    end
    val
  end

  # Update the estimated cost of the ALI based on the assets
  def update_estimated_cost
    self.estimated_cost = total_asset_cost
    save
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
  end

end
