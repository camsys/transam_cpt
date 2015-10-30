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

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  # Every capital project belongs to an organization
  belongs_to  :organization

  # Every CP has a single TEAM sub catagory code
  belongs_to  :team_ali_code

  # Every CP has a single type
  belongs_to  :capital_project_type

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
  validates :project_number,                    :presence => true
  validates :title,                             :presence => true
  validates :description,                       :presence => true
  validates :justification,                     :presence => true
  validates :fy_year,                           :presence => true, :numericality => {:only_integer => :true, :greater_than_or_equal_to => 1900}

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------

  # Allow selection of active instances
  scope :active, -> { where(:active => true) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    #:project_number,
    :organization_id,
    :fy_year,
    :team_ali_code_id,
    :capital_project_type_id,
    :state,
    :title,
    :description,
    :justification,
    :emergency,
    :active
  ]
  # List of fields which can be searched using a simple text-based search
  SEARCHABLE_FIELDS = [
    :object_key,
    :project_number,
    :title,
    :description,
    :justification,
    :capital_project_type,
    :fy_year,
    :team_ali_code
  ]

  #------------------------------------------------------------------------------
  #
  # State Machine
  #
  # Used to track the state of a capital project through the approval process
  #
  #------------------------------------------------------------------------------
  state_machine :state, :initial => :unsubmitted do

    #-------------------------------
    # List of allowable states
    #-------------------------------

    # initial state. All CPs are created in this state
    state :unsubmitted

    # state used to signify it has been submitted by the organization and is pending review
    state :pending_review

    # state used to signify that the CP has been returned for further work.
    state :returned

    # state used to signify that the CP has been approved
    state :approved

    #---------------------------------------------------------------------------
    # List of allowable events. Events transition a CP from one state to another
    #---------------------------------------------------------------------------

    # Retract the project from consideration
    event :retract do
      transition [:returned, :pending_review, :approved] => :unsubmitted
    end

    # submit a CP for approval. This will place the CP in the approvers queue
    event :submit do
      transition [:unsubmitted, :returned] => :pending_review
    end

    # An approver is returning a project for additional information or changes
    event :return do
      transition [:pending_review] => :returned
    end

    # An approver is approving a project
    event :approve do
      transition [:pending_review] => :approved
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
    if ["approved"].include? state
      false
    else
      true
    end
  end

  # Returns true if the project is an SOGR project that was created by the SOGR
  # builder
  def sogr?
    (sogr)
  end
  # Returns true if the project is an multi-year project. These can only be created
  # for facility projects
  def multi_year?
    (multi_year)
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
    activity_line_items.each {|x| val += x.state_funds}
    val
  end

  def federal_funds
    val = 0
    activity_line_items.each {|x| val += x.federal_funds}
    val
  end

  def local_funds
    val = 0
    activity_line_items.each {|x| val += x.local_funds}
    val
  end

  def total_funds
    val = 0
    activity_line_items.each {|x| val += x.total_funds}
    val
  end

  # Returns the total cost of the project
  def total_cost
    val = 0
    activity_line_items.each {|x| val += x.cost}
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

  def searchable_fields
    SEARCHABLE_FIELDS
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
    self.active     ||= true
    self.sogr       ||= false
    self.multi_year ||= false
    self.emergency  ||= false
    self.state      ||= :unsubmitted
    self.project_number ||= 'TEMP'
    # Set the fiscal year to the current fiscal year which can be different from
    # the calendar year
    self.fy_year    ||= current_fiscal_year_year
  end

end
