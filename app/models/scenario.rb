class Scenario < ApplicationRecord
  # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  # Include the Workflow module
  include TransamWorkflow

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :organization_id,
    :fy_year
  ]

  CANCELLABLE_STATES = [
    :unconstrained_plan, 
    :submitted_unconstrained_plan, 
    :constrained_plan, 
    :submitted_constrained_plan
  ]

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to  :organization
  has_many :draft_projects

  #------------------------------------------------------------------------------
  #
  # State Machine
  #
  # Used to track the state of a task order through the completion process
  #
  #------------------------------------------------------------------------------
  state_machine :state, :initial => :unconstrained_plan do

    #-------------------------------
    # List of allowable states
    #-------------------------------

    # initial state. All tasks are created in this state
    state :unconstrained_plan

    # state used to signify it has been started but not completed
    state :submitted_unconstrained_plan

    state :constrained_plan
    state :submitted_unconstained_plan
    state :final_draft
    state :awaiting_final_approval

    # state used to signify it has been completed
    state :approved

    # nevermind
    state :cancelled

    #---------------------------------------------------------------------------
    # List of allowable events. Events transition a task from one state to another
    #---------------------------------------------------------------------------

    event :submit do
      transition :unconstrained_plan => :submitted_unconstrained_plan
      transition :constrained_plan => :submitted_constrained_plan
    end

    event :reject do
      transition :submitted_unconstrained_plan => :unconstrained_plan
      transition :submitted_constrained_plan => :constrained_plan
      transition :final_draft => :submitted_constrained_plan
      transition :awaiting_final_approval => :final_draft
    end

    event :accept do
      transition :submitted_unconstrained_plan => :constrained_plan
      transition :submitted_constrained_plan => :final_draft
      transition :final_draft => :awaiting_final_approval
      transition :awaiting_final_approval => :approved
    end

    # Nevermind
    event :cancel do
      transition CANCELLABLE_STATES => :cancelled
    end

  end

  def cancellable? 
    state.to_sym.in? CANCELLABLE_STATES
  end

  #------------------------------------------------------------------------------
  # Text Helpers
  #------------------------------------------------------------------------------
  def description
    case state.to_sym
    when :approved
      "This scenario is complete and all projects have been updated."
    when :cancelled
      "This scenario has been cancelled."
    when :unconstrained_plan
      "Define all the unfunded projects needed and submit the project to BPT."
    when :submitted_unconstrained_plan
      "BPT should review the status of this unconstrained plan."
    when :constrained_plan
      "Transit Agency adds local and federal funding"
    when :submitted_constrained_plan
      "BPT adds state funding"
    when :final_draft
      "TA Approves Final Funding before final approval"
    when :awaiting_final_approval
      "BPT Needs Approval from XYX"
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

end
