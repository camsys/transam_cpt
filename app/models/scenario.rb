class Scenario < ApplicationRecord
  # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  # Include the Workflow module
  include TransamWorkflow

  #Formatting i.e. fiscal year
  include TransamFormatHelper

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :organization_id,
    :fy_year,
    :name,
    :description
  ]

  CANCELLABLE_STATES = [
    :unconstrained_plan, 
    :submitted_unconstrained_plan, 
    :constrained_plan, 
    :submitted_constrained_plan
  ]

  CHART_STATES = [ # states to be included 
    "constrained_plan",
    "submitted_constrained_plan",
    "final_draft",
    "awaiting_final_approval",
    "approved"
  ]


  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to  :organization
  has_many :draft_projects
  has_many :draft_project_phases, through: :draft_projects
  has_many :draft_project_phase_assets, through: :draft_project_phases

  has_many    :comments,    :as => :commentable,  :dependent => :destroy

  alias phases draft_project_phases #just to save on typing
  alias projects draft_projects

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :name, presence: true 
  validates :organization_id, presence: true 


  #------------------------------------------------------------------------------
  # Instance Methods
  #------------------------------------------------------------------------------
  def cost
     phases.pluck(:cost).sum
  end 

  def allocated
    phases.map{ |phase| phase.allocated }.sum
  end

  def remaining
    cost - allocated
  end

  def percent_funded
    return 0 if cost == 0
    return (100*(allocated.to_f/cost.to_f)).round
  end


  #------------------------------------------------------------------------------
  #
  # Chart Helpers
  #
  #------------------------------------------------------------------------------

  def year_range
    earliest = phases.min_by(&:fy_year)
    latest = phases.max_by(&:fy_year)
    return (earliest.fy_year..latest.fy_year)
  end

  def sum_phases_by_year
    d = {}
    self.year_range.each do |y| #quick patch
      d[y] = 0
    end
    phases.each do |phase|
      if d[phase.fy_year]
        d[phase.fy_year] = d[phase.fy_year] + phase.cost
      else
        d[phase.fy_year] = phase.cost
      end
    end
    return d
  end

  def self.year_to_cost_ali_breakdown scenario=nil
    d = []
    if scenario
      ali_to_projects = scenario.draft_projects.group_by { |p| p.team_ali_code } 
    else
      scenarios = Scenario.where(state: CHART_STATES)
      ali_to_projects = DraftProject.where(scenario: scenarios).group_by { |p| p.team_ali_code }
    end
    ali_to_projects.each do |ali, projects|
      x = {name: ali.to_s + " " + ali.try(:context).to_s, data: {}}
      (2021..2033).each{ |y| x[:data][y] = 0 }
      projects.each do |pr|
        pr.year_to_cost.each do |year, cost|
          x[:data][year] += cost
        end
      end
      d.push(x)
    end
    # d.each do |h|
    #   h[:data] = h[:data].to_a.map{ |y_c| [y_c[0], y_c[1]] } #patch for formatting
    # end
    return d
  end

  def in_chart_state?
    state.to_sym.in? CHART_STATES
  end

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
  def state_description
    case state.to_sym
    when :approved
      "This scenario is complete and all projects have been updated."
    when :cancelled
      "This scenario has been cancelled."
    when :unconstrained_plan
      "#{self.organization.try(:name)} defines all the projects needing funding and submits them to BPT."
    when :submitted_unconstrained_plan
      "BPT reviews the status of this unconstrained plan."
    when :constrained_plan
      "#{self.organization.try(:name)} adds local and federal funding."
    when :submitted_constrained_plan
      "BPT adds state funding."
    when :final_draft
      "#{self.organization.try(:name)} reviews the funding amounts allocated by BPT."
    when :awaiting_final_approval
      "BPT gets approval from Final Approvers."
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
