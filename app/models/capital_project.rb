#------------------------------------------------------------------------------
#
# CapitalProject
#
# Represents a capital project in TransAM. Each capital project is composed of
# one or more ActivityLineItems and is associated with a particular fiscal year.
#
#------------------------------------------------------------------------------
class CapitalProject < ActiveRecord::Base
    
  # Include the unique key mixin
  include UniqueKey
  # Include the fiscal year mixin
  include FiscalYear
  # Include the ali code mixin
  include AssetAliLookup

  #------------------------------------------------------------------------------
  # Overrides
  #------------------------------------------------------------------------------
  
  #require rails to use the asset key as the restful parameter. All URLS will be of the form
  # /capital_project/{object_key}/...
  def to_param
    object_key
  end
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize                  :set_defaults
  # Always generate a unique project number when the project is created
  after_create do
    create_project_number
  end
  # Always generate a unique object key before saving to the database
  before_validation(:on => :create) do
    generate_unique_key(:object_key)
  end
      
  # Clean up any HABTM associations before the asset is destroyed
  before_destroy { mpms_projects.clear }
      
  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  # Every capital project belongs to an organization
  belongs_to  :organization

  # Has a single project status
  belongs_to  :capital_project_status_type

  # Every CP has a single TEAM sub catagory code
  belongs_to  :team_ali_code

  # Every CP has a single type 
  belongs_to  :capital_project_type

  # Has many MPMS projects. These will be removed if the project is removed
  has_and_belongs_to_many    :mpms_projects
    
  # Has 0 or more activity line items. These will be removed if the project is removed.
  has_many    :activity_line_items, :dependent => :destroy

  # Has 0 or more documents. Using a polymorphic association. These will be removed if the project is removed
  has_many    :documents,   :as => :documentable, :dependent => :destroy

  # Has 0 or more comments. Using a polymorphic association, These will be removed if the project is removed
  has_many    :comments,    :as => :commentable,  :dependent => :destroy

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :object_key,                        :presence => true, :uniqueness => true
  validates :organization_id,                   :presence => true
  validates :team_ali_code_id,                  :presence => true
  validates :capital_project_type_id,           :presence => true
  validates :capital_project_status_type_id,    :presence => true
  #validates :project_number,                    :presence => true, :uniqueness => true
  validates :title,                             :presence => true
  validates :description,                       :presence => true
  validates :justification,                     :presence => true
  validates :fy_year,                           :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 2000}

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # default scope
  default_scope { where(:active => true) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    #:project_number, 
    :organization_id,
    :fy_year,
    :team_ali_code_id,
    :capital_project_type_id,
    :capital_project_status_type_id, 
    :title,
    :description,
    :justification,
    :emergency,
    :active,
    :mpms_project_ids => []
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
  
  # Returns assets which could be added to this capital project
  def candidate_assets
    
    # Ensure we have enough detail to work with
    if organization.nil? or capital_project_type.nil?
      return []
    end

    # Only suitable for vehicle replacement and rehabilitation projects so far
    if capital_project_type.id > 3
      return []
    end
    
     # Start to set up the query
    conditions  = []
    values      = []
    
    # Only for the project organization
    conditions << 'organization_id = ?'
    values << organization.id

    # 1 = SOGR Replacement
    # 2 = SOGR Rehabilitation
    # 3 = SOGR Rail Mid-life rebuild
    if [1].include? capital_project_type.id
      conditions << 'scheduled_replacement_year = ?'
      values << fy_year
    elsif [2,3].include? capital_project_type.id
      conditions << 'scheduled_rehabilitation_year = ?'
      values << fy_year
    end    
        
    # Get the children of this project type and use it to select 
    # possible subtypes
    asset_subtype_ids = []
    team_ali_code.children.each do |ali|
      # use the mixin to get the correct subtype from the ALI code
      asset_subtypes = asset_subtypes_from_ali_code(ali.code)
      asset_subtypes.each do |type|
        # add it to our list
        asset_subtype_ids << type.id
      end
    end
    # add to our query
    unless asset_subtype_ids.empty?
      conditions << 'asset_subtype_id IN (?)'
      values << asset_subtype_ids.uniq
    end
        
    Asset.where(conditions.join(' AND '), *values).order(:asset_type_id, :asset_subtype_id)
    
  end
  def state_request
    val = 0
    activity_line_items.each do |a|
      val += a.state_request
    end
    val
  end
  def federal_request
    val = 0
    activity_line_items.each do |a|
      val += a.federal_request
    end
    val
  end
  def local_request
    val = 0
    activity_line_items.each do |a|
      val += a.local_request
    end
    val
  end
  def total_request
    state_request + federal_request + local_request
  end
  # Override the mixin method and delegate to it
  def fiscal_year
    super(fy_year)
  end
  
  # returns true if the project can be scheduled on year earlier
  def can_schedule_earlier?
    # return true if the projects fiscal year is greater than the current fiscal year
    fy_year > current_fiscal_year_year
  end
  
  def name
    project_number
  end
    
  def update_project_number
    create_project_number
  end
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected 

  def create_project_number
    years = fiscal_year.split[1]
    project_number = "CCA-G-#{years}-#{organization.short_name}-#{team_ali_code.type_and_category}-#{id}"
    self.update_attributes(:project_number => project_number)      
  end

  # Set resonable defaults for a new capital project
  def set_defaults
    self.active ||= true
    self.emergency ||= false
    self.capital_project_status_type_id ||= 1
    # Set the fiscal year to the current fiscal year which can be different from
    # the calendar year
    self.fy_year ||= current_fiscal_year_year 
  end    
      
end
