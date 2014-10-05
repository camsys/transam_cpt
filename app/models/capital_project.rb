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
  validates :state,                             :presence => true
  #validates :project_number,                    :presence => true, :uniqueness => true
  validates :title,                             :presence => true
  validates :description,                       :presence => true
  validates :justification,                     :presence => true
  validates :fy_year,                           :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => Date.today.year}

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
    :title,
    :description,
    :justification,
    :emergency,
    :active,
    :mpms_project_ids => []
  ]
  
  #------------------------------------------------------------------------------
  #
  # State Machine 
  #
  # Used to track the state of a capital project through the BPT approval process
  #
  #------------------------------------------------------------------------------  
  state_machine :state, :initial => :unsubmitted do

    #-------------------------------
    # List of allowable states
    #-------------------------------
    
    # initial state. All CPs are created in this state
    state :unsubmitted
    
    # state used to signify it has been submitted and is pending approval 
    state :pending_approval

    # state used to signify that the CP has been conditionally by the program manager.
    # The project is waiting for statewide approval
    state :conditionally_approved
    
    # state used to signify that the CP has been approved by the program manager
    state :approved

    # state used to signify that the CP has been returned by the program manager. PM
    # has asked for additional information/changes etc.
    state :returned

    # state used to indicate the the CP has been funded and moved into dotGrants/CCA
    state :funded

    #---------------------------------------------------------------------------
    # List of allowable events. Events transition a CP from one state to another
    #---------------------------------------------------------------------------
            
    # reset the project to its initial state
    event :reset do
      transition all => :unsubmitted
    end

    # submit a CP for approval. This will place the CP in the program managers
    # queue. 
    event :submit do
      
      transition [:unsubmitted, :returned] => :pending_approval
      
    end

    # A program manager is conditionally approving a project
    event :conditionally_approve do
      
      transition :pending_approval => :conditionally_approved
      
    end    

    # A program manager is returning a project for additional information or changes
    event :return do
      
      transition :pending_approval => :returned
      
    end    

    # A program manager is approving a project
    event :approve do
      
      transition [:pending_approval, :conditionally_approved] => :approved
      
    end    

    # A program manager is funding a project
    event :fund do
      
      transition [:approved] => :funded
      
    end     
    
    # Callbacks
    before_transition do |project, transition|
      Rails.logger.debug "Transitioning #{project}"
    end       
  end

  
  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
    
  def self.allowable_params
    FORM_PARAMS
  end
  
  def self.state_names
    a = []
    state_machine.states.each do |s|
      a << s.name.to_s
    end
    a
  end
  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------
    
  def state_request
    val = 0
    activity_line_items.each do |a|
      val += a.state_funds
    end
    val
  end
  
  def federal_request
    val = 0
    activity_line_items.each do |a|
      val += a.federal_funds
    end
    val
  end
  
  def local_request
    val = 0
    activity_line_items.each do |a|
      val += a.local_funds
    end
    val
  end
  
  def total_request
    val = 0
    activity_line_items.each do |a|
      val += a.total_funds
    end
    val
  end
  
  # Returns the total cost of the project
  def total_cost
    val = 0
    activity_line_items.each do |a|
      val += a.cost
    end
    val    
  end
  
  # Returns the amount that is not yet funded
  def funding_difference
    total_cost - total_request
  end
  
  # Override the mixin method and delegate to it
  def fiscal_year
    super(fy_year)
  end
    
  def to_s
    project_number
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
    project_number = "#{organization.short_name}-#{years}-#{team_ali_code.scope}-#{id}"
    self.update_attributes(:project_number => project_number)      
  end

  # Set resonable defaults for a new capital project
  def set_defaults
    self.active ||= true
    self.emergency ||= false
    self.state ||= :unsubmitted
    # Set the fiscal year to the current fiscal year which can be different from
    # the calendar year
    self.fy_year ||= current_fiscal_year_year 
  end    
            
end
