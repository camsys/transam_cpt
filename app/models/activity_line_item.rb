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
    
  # Include the unique key mixin
  include UniqueKey

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the asset key as the restful parameter. All URLS will be of the form
  # /activity_line_item/{object_key}/...
  def to_param
    object_key
  end
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize :set_defaults
  
  # Always generate a unique object key before saving to the database
  before_validation(:on => :create) do
    generate_unique_key(:object_key)
  end
  
  # Clean up any HABTM associations before the ali is destroyed
  before_destroy { assets.clear }

  # Before saving this ALI, make sure the total estimated cost is updated
  before_save do
    update_estimated_cost
  end  
  
  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  
  # Every ali belongs to a capital project
  belongs_to  :capital_project

  # Every ALI has a single TEAM sub catagory code
  belongs_to  :team_ali_code
    
  # Has 0 or more assets
  has_and_belongs_to_many    :assets
    
  # Has 0 or more milestones
  has_many    :milestones
  
  # Has 0 or more funding requests, These will be removed if the project is removed.
  has_many    :funding_requests, :dependent => :destroy

  # Has 0 or more comments. Using a polynmorphic association
  has_many    :comments,  :as => :commentable
  
  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => true, :uniqueness => true
  validates :capital_project_id,                :presence => true
  validates :name,                              :presence => true
  validates :anticipated_cost,                  :presence => :true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}
  validates :team_ali_code_id,                  :presence => true


  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # default scope
  default_scope { where(:active => true) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :capital_project_id, 
    :name,
    :team_ali_code_id, 
    :anticipated_cost,
    :active,
    :asset_ids => []    
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
  
  # Returns the set of federal funding requests
  def federal_funding_requests
    #funding_requests.where("funding_amount.funding_source.funding_source_type_id = ?", 1)
    []
  end
  # Returns the set of state funding requests
  def state_funding_requests
    #funding_requests.where("funding_amount.funding_source.funding_source_type_id = ?", 2)
    []
  end
  # Returns the set of local funding requests
  def local_funding_requests
    #funding_requests.where("funding_amount.funding_source.funding_source_type_id = ?", 3)
    []
  end
  
  # Returns the total value of federal funds requested
  def federal_funds
    val = 0
    federal_funding_requests.each do |a|
      val += a.amount
    end
    val
  end
  # Returns the total value of state funds requested
  def state_funds
    val = 0
    state_funding_requests.each do |a|
      val += a.amount
    end
    val
  end
  # Returns the total value of local funds requested
  def local_funds
    val = 0
    local_funding_requests.each do |a|
      val += a.amount
    end
    val
  end
  # Returns the total amount of funds requested
  def total_funds
    val = 0
    funding_requests.each do |a|
      val += a.amount
    end
    val     
  end
  
  # Returns the amount that is not yet funded
  def funding_difference
    estimated_cost - total_funds
  end
  
  # Returns the cost difference between the anticpated cost by the user and the cost estimated
  # by the system
  def cost_difference
    anticpated_cost - estimated_cost
  end
  
  # Returns the total estiamted value of the assets in this ALI
  def total_estimated_value
    val = 0
    assets.each do |a|
      val += a.estimated_value unless a.estimated_value.nil?
    end
    val
  end

  # Returns the total original purchase cost of the assets in this ALI
  def total_original_cost
    val = 0
    assets.each do |a|
      val += a.cost unless a.cost.nil?
    end
    val
  end

  # Returns the total estimated replacment cost of the assets in this ALI
  def total_estimated_replacement_cost
    val = 0
    assets.each do |a|
      val += a.estimated_replacement_cost unless a.estimated_replacement_cost.nil?
    end
    val
  end
  
  # Update the estiamted cost of the ALI based on the assets
  def update_estimated_cost
    self.estimated_cost = total_estimated_replacement_cost    
  end
  
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 


  # Set resonable defaults for a new activity line item
  def set_defaults
    self.active ||= true
    self.estimated_cost ||= 0
    self.anticipated_cost ||= 0
  end    
      
end
