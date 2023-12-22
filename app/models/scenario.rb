class Scenario < ApplicationRecord
  # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  # Include the Workflow module
  include TransamWorkflow

  #Formatting i.e. fiscal year
  include TransamFormatHelper

  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize :set_defaults

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :organization_id,
    :fy_year,
    :ending_fy_year,
    :name,
    :description,
    :email_updates,
    :reviewer_organization_id,
    :state  
  ]

  CANCELLABLE_STATES = [
    :unconstrained_plan, 
    :submitted_unconstrained_plan, 
    :constrained_plan, 
    :submitted_constrained_plan,
    :final_draft,
    :awaiting_final_approval
  ]

  # STATE WHERE WE ARE DEALING WITH BUDGETS
  CONSTRAINED_STATES = [ # states to be included 
    "constrained_plan",
    "submitted_constrained_plan",
    "final_draft",
    "awaiting_final_approval",
    "approved"
  ]

  # STATES WHERE ONLY ONE SCENARIO CAN EXIST PER YEAR
  SUBMITTED_STATES = [ # states to be included 
    "submitted_unconstrained_plan",
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
  belongs_to  :reviewer_organization, class_name: 'Organization', foreign_key: 'reviewer_organization_id'
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
  validates :fy_year, presence: true 
  validates :ending_fy_year, presence: true
  validates :primary_scenario, uniqueness: {scope: [:organization, :fy_year]}, if: :primary_scenario

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------
  scope :approved, -> { where(state: "approved") }
  scope :in_constrained_state, -> { where(state: CONSTRAINED_STATES) }
  scope :in_submitted_state, -> { where(state: SUBMITTED_STATES) }


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
    percent = (100*(allocated.to_f/cost.to_f)).round
    if percent == 100 && allocated.to_f != cost.to_f
      percent = 99
    end
    return percent
  end

  
  def copy(pinned_only=false, include_comments=true, starting_year=nil)

    # Copy over the Scenario Attributes
    attributes = {}
    FORM_PARAMS.each do |param|
      attributes[param] = self.send(param)
    end   
    new_scenario = Scenario.create(attributes)
    new_scenario.name = "#{new_scenario.name} (Copy)"
    if new_scenario.state.in? SUBMITTED_STATES
      new_scenario.state = "unconstrained_plan"
    end
    new_scenario.save 

    # Copy over the Projects and The Children of Projects
    draft_projects.each do |dp|
      dp.copy(new_scenario, pinned_only, starting_year)
    end

    if include_comments
      # Copy over the comments
      comments.each do |comment|
        Comment.create!(
          commentable_id: new_scenario.id, 
          commentable_type: comment.commentable_type, 
          comment: comment.comment,
          created_by_id: comment.created_by_id,
          created_at: comment.created_at
        )
      end
    end

    new_scenario

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

  def self.peaks_and_valleys_chart_data(scenario=nil, year=nil)
    data = []
    year ||= self.current_fiscal_year_year

    # If we are within a scenario, only pull projects from that scenario. Otherwise, pull projects form all scenarios in the constrained phases or beyond
    if scenario
      year_range = (scenario.fy_year..scenario.ending_fy_year)
      projects = scenario.draft_projects
    else
      year_range = (year.to_i..(year.to_i+12))
      scenarios = Scenario.in_constrained_state.where(fy_year: year)
      projects = DraftProject.where(scenario_id: scenarios.pluck(:id)).uniq
    end

    # Get all the phases and group them by ALI
    ali_to_phases = DraftProjectPhase.where(draft_project_id: projects.pluck(:id)).group_by { |phase| phase.parent_ali_code } 

    # Iterate through each ALI and add up the costs
    ali_to_phases.each do |ali, phases|
      new_entry = {name: "#{ali.try(:code) || 'None'} #{ali.try(:context)}"}
      data_hash = {}

      # First create an empty hash entry for each year
      year_range.each do |year|
        data_hash[year] = 0
      end

      # Iterate through each phase and add it to the corresponding year
      phases.each do |phase|
        phase_year = phase.fy_year 
        if data_hash[phase_year]
          data_hash[phase_year] += phase.cost 
        else
          data_hash[phase_year] = phase.cost 
        end
      end

      # Convert the hash to an array, and also convert the year to be the fiscal year.
      data_array = data_hash.map{ |k,v| [SystemConfig.fiscal_year(k.to_i),v] }

      new_entry[:data] = data_array

      data << new_entry 

    end

    return data

  end

  def in_chart_state?
    state.to_sym.in? CONSTRAINED_STATES
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

    event :reopen do
      transition :cancelled => :unconstrained_plan
    end

    #---------------------------------------------------------------------------
    # Transition actions
    #---------------------------------------------------------------------------

    after_transition :mark_assets_underway, all => :approved
    
  end

  #---------------------------------------------------------------------------
  # Serializers and Exporters
  #---------------------------------------------------------------------------
  def dotgrants_json
    export = {environment: Rails.env}

    #Add on the ALIs
    export[:activity_line_items] = draft_project_phases.where(fy_year: fy_year).map{ |ali| ali.dotgrants_json}
    export[:funding_templates] = FundingTemplate.all.map{ |funding_template| funding_template.as_json }
    if organization.organization_type == OrganizationType.find_by(class_name: "TransitOperator")
      export[:email] = organization.executive_director&.email
    end
    export[:fein] = organization.subrecipient_number
    return export 
  end 


  #---------------------------------------------------------------------------
  # State Helper Methods
  #---------------------------------------------------------------------------
  def cancellable? 
    state.to_sym.in? CANCELLABLE_STATES
  end

  def state_owner
    case state.to_sym
    when :approved
      nil
    when :unconstrained_plan, :constrained_plan, :final_draft
      organization 
    when :submitted_unconstrained_plan, :submitted_constrained_plan, :awaiting_final_approval, :cancelled
      reviewer_organization
    end
  end

  def mark_assets_underway
    underway_id = ReplacementStatusType.where(name: 'Underway').pluck(:id).first
    comment = "The #{name} plan includes the replacement of this asset."
    draft_project_phases.where(fy_year: fy_year).each do |dpp|
      dpp.transit_assets.each do |ta|
        ReplacementStatusUpdateEvent.create(transam_asset: ta.transam_asset, replacement_year: fy_year,
                                            replacement_status_type_id: underway_id, comments: comment)
      end
    end
  end
  
  #---------------------------------------------------------------------------
  # State Machine Validations
  #---------------------------------------------------------------------------
  def validate_transition action 
    case state
    when "unconstrained_plan"
      if action == "submit"
        return no_other_submitted_scenarios_for_this_year?
      end 
    when "constrained_plan"
      if action == "submit"
        return (no_estimated_costs_in_year_1? and no_local_or_federal_budget_placeholders_in_year_1? and all_required_milestones_are_present_in_year_1?)
      end
    when "submitted_constrained_plan"
      if action == "accept"
        return no_budget_placeholders_in_year_1?
      end 
    end
    return true 
  end

  # Validation Methods
  def no_local_or_federal_budget_placeholders_in_year_1?
    draft_project_phases.where(fy_year: fy_year).each do |phase|
      phase.draft_budgets.where(default: true).each do |budget|
        if budget.funding_source_type.try(:name).in? ["Federal", "Local"]
          self.errors.add(:funding, "Please update all Federal and Local placeholder budgets for #{SystemConfig.fiscal_year(fy_year)}.")
          return false
        end
      end
    end
    return true
  end

  def no_budget_placeholders_in_year_1?
    draft_project_phases.where(fy_year: fy_year).each do |phase|
      if phase.draft_budgets.where(default: true).count > 0
        self.errors.add(:funding, "Please remove all placeholder budgets for #{SystemConfig.fiscal_year(fy_year)}.")
        return false
      end
    end
    return true
  end

  def no_estimated_costs_in_year_1?
    if draft_project_phases.where(fy_year: fy_year, cost_estimated: true).count > 0
      self.errors.add(:funding, "Please update all estimated costs for #{SystemConfig.fiscal_year(fy_year)}.")
      return false
    end
    return true
  end

  def all_required_milestones_are_present_in_year_1?
    phase_ids = draft_project_phases.where(fy_year: fy_year).pluck(:id)
    if Milestone.required.where(draft_project_phase_id: phase_ids).where(milestone_date: nil).count > 0
      self.errors.add(:milestones, "Please add required milestones for all ALIs in #{SystemConfig.fiscal_year(fy_year)}.")
      return false
    end 
    return true 
  end

  def no_other_submitted_scenarios_for_this_year?
    if Scenario.in_submitted_state.where(fy_year: fy_year, organization: organization).count > 0
      self.errors.add(:state, "Only one scenario can be submitted at a time.")
      return false
    end 
    return true
  end


  #------------------------------------------------------------------------------
  #
  # Text Helpers
  #
  #------------------------------------------------------------------------------
  def state_description
    case state.to_sym
    when :approved
      "This scenario is complete and all projects have been updated."
    when :cancelled
      "This scenario has been closed."
    when :unconstrained_plan
      "#{self.organization.try(:name)} defines all the projects needing funding and submits them to #{reviewer_organization.try(:short_name) || 'the reviewer'}."
    when :submitted_unconstrained_plan
      "#{reviewer_organization.try(:short_name) || 'The reviewer'} reviews the status of this unconstrained plan."
    when :constrained_plan
      "#{self.organization.try(:name)} adds local and federal funding."
    when :submitted_constrained_plan
      "#{reviewer_organization.try(:short_name) || 'The reviewer'} adds state funding."
    when :final_draft
      "#{self.organization.try(:name)} reviews the funding amounts allocated by #{reviewer_organization.try(:short_name) || 'the reviewer'}."
    when :awaiting_final_approval
      "#{reviewer_organization.try(:short_name) || 'The reviewer'} gets approval from Final Approvers."
    end
  end

  def past_tense transition
    case transition.to_s
    when "cancel"
      return "Closed"
    when "accept"
      return "accepted"
    when "reject"
      return "rejected"
    when "submit"
      return "submitted"
    when "reopen"
      return "reopened"
    end
  end

  def state_title
    if state == "cancelled"
      return "Closed"
    else
      return state.titleize
    end
  end

  def name_with_year 
    if fy_year
      return "#{name} (#{SystemConfig.fiscal_year(fy_year)})"
    else 
      return name 
    end
  end

  #------------------------------------------------------------------------------
  # Mail Helpers
  #------------------------------------------------------------------------------

  def send_transition_email transition 
    subject = "#{name} has been #{past_tense transition}."
    users = (User.with_role :manager).where(organization: state_owner)
    if users.blank? #No managers here, send to all users at this org
      users = User.where(organization: state_owner)
    end
    emails = users.pluck(:email)

    CptMailer.transition(emails, subject, self).deliver! unless emails.blank?
  end


  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  #Unable to access the FiscalYear module from class methods. Copied teh current fiscal year method from there to here.
  def self.current_fiscal_year_year
    SystemConfig.instance.fy_year
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  # Set resonable defaults for a new scenario
  def set_defaults
    self.fy_year ||= current_planning_year_year
    self.ending_fy_year ||= current_planning_year_year
    self.reviewer_organization ||= Organization.find_by(organization_type: OrganizationType.where(name: 'Grantor'))
  end
end
