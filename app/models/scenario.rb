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

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  # Every scenario belongs to an organization
  belongs_to  :organization

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

    # state used to signify it has been completed
    state :completed

    # nevermind
    state :cancelled

    #---------------------------------------------------------------------------
    # List of allowable events. Events transition a task from one state to another
    #---------------------------------------------------------------------------

    # Submit the unsubmitted plan to approvers
    event :submit_unconstrained_plan do
      transition :unconstrained_plan => :submitted_unconstrained_plan
    end

    # Done!
    event :complete do
      transition :submitted_unconstrained_plan => :completed
    end

    # Nevermind
    event :cancel do
      transition [:unconstrained_plan, :submitted_unconstrained_plan] => :cancelled
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
