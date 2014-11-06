#------------------------------------------------------------------------------
#
# CapitalProject
#
# Represents a capital project in TransAM. Each capital project is composed of
# one or more ActivityLineItems and is associated with a particular fiscal year.
#
#------------------------------------------------------------------------------
class CapitalProject < ActiveRecord::Base
    
  # Include the object key mixin
  include TransamObjectKey
  
  # Include the fiscal year mixin
  include FiscalYear
  # Include the ali code mixin
  include AssetAliLookup
  
  # Include the Workflow module
  include TransamWorkflow
  
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize                  :set_defaults
  
  # Always generate a unique project number when the project is created
  after_create do
    create_project_number
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
  validates :organization,                      :presence => true
  validates :team_ali_code,                     :presence => true
  validates :capital_project_type,              :presence => true
  validates :state,                             :presence => true
  #validates :project_number,                    :presence => true, :uniqueness => true
  validates :title,                             :presence => true
  validates :description,                       :presence => true
  validates :justification,                     :presence => true
  #validates :fy_year,                           :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => CapitalProject.new.fiscal_year_epoch_year}

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  
  # default scope
  default_scope { where(:active => true) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
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
    
    # state used to signify it has been submitted and is pending review 
    state :pending_review

    # state used to signify it has been reviewed and accepted
    state :accepted

    # state used to signify that the CP has been returned by the program manager. PM
    # has asked for additional information/changes etc.
    state :returned

    # state used to signify that the CP has been conditionally by the program manager.
    # The project is waiting for statewide approval
    state :conditionally_approved
    
    # state used to signify that the CP has been approved by the program manager
    state :approved

    # state used to indicate the the CP has been funded and moved into dotGrants/CCA
    state :funded

    #---------------------------------------------------------------------------
    # List of allowable events. Events transition a CP from one state to another
    #---------------------------------------------------------------------------
            
    # Retract the project from consideration
    event :retract do
      transition [:returned, :pending_review, :accepted, :conditionally_approved] => :unsubmitted
    end

    # submit a CP for approval. This will place the CP in the program managers
    # queue. 
    event :submit do
      
      transition [:unsubmitted, :returned] => :pending_review
      
    end

    # A program manager is accepting a project
    event :accept do
      
      transition :pending_review => :accepted
      
    end    

    # A program manager is conditionally approving a project
    event :conditionally_approve do
      
      transition :accepted => :conditionally_approved
      
    end    

    # A program manager is returning a project for additional information or changes
    event :return do
      
      transition [:pending_review, :accepted, :conditionally_approved] => :returned
      
    end    

    # A program manager is approving a project
    event :approve do
      
      transition [:accepted, :conditionally_approved] => :approved
      
    end    

    # A program manager is funding a project
    event :fund do
      
      transition [:approved] => :funded
      
    end     
    
    # Callbacks
    before_transition do |project, transition|
      Rails.logger.debug "Transitioning #{project.name} from #{transition.from_name} to #{transition.to_name} using #{transition.event}"
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
  
  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------
    
  # The project can be updated if it has not been approved and/or funded
  def can_update?
    if ["conditionally_approved", "funded", "approved"].include? state
      false
    else
      true
    end
  end
    
  # Returns true if the project's total cost has been set and 
  # funding requests have been entered that cover the cost
  def can_submit?
    # First check the state machine to see if it is Ok to submit based on the 
    # current state
    b = super()
    if b
      # Now check that the CP has funding
      b = false unless total_cost > 0
      #b = false unless funding_difference <= 0
    end
    b
  end
  
  def state_funds
    val = 0
    activity_line_items.each do |a|
      val += a.state_funds
    end
    val
  end
  
  def federal_funds
    val = 0
    activity_line_items.each do |a|
      val += a.federal_funds
    end
    val
  end
  
  def local_funds
    val = 0
    activity_line_items.each do |a|
      val += a.local_funds
    end
    val
  end
  
  def total_funds
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
    total_cost - total_funds
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
