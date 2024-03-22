class DraftProjectPhase < ApplicationRecord

  # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  FORM_PARAMS = [
    :name,
    :cost,
    :fy_year,
    :cost_justification,
    :draft_project_id,
    :team_ali_code_id,
    :fuel_type_id,
    :pinned,
    :cost_estimated,
    :count
  ]

  # SQL clause for cost sum-up
  # this is also used in CapitalProject related cost calculation
  COST_SUM_SQL_CLAUSE = "(CASE WHEN draft_project_phases.cost > 0 THEN draft_project_phases.cost ELSE draft_project_phases.cost_estimated END)"

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :draft_project
  delegate :scenario, to: :draft_project
  belongs_to :team_ali_code
  belongs_to :fuel_type
  has_many :draft_funding_requests, :dependent => :destroy
  has_many :draft_budget_allocations, through: :draft_funding_requests
  has_many :draft_budgets, through: :draft_budget_allocations
  has_many :draft_project_phase_assets, :dependent => :destroy
  has_many :transit_assets, through: :draft_project_phase_assets
  has_many :milestones, :dependent => :destroy

  #------------------------------------------------------------------------------
  # Milestones
  #------------------------------------------------------------------------------
  after_create :add_milestones
  after_create :add_funding_request

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :cost, presence: true 
  validates :fy_year, presence: true

  #------------------------------------------------------------------------------
  # Instance Methods
  #------------------------------------------------------------------------------
  def get_fiscal_year
    fiscal_year(fy_year)
  end 

  def allocated
    draft_budget_allocations.pluck(:amount).sum
  end

  def placeholder_total
    draft_budget_allocations.select{ |a| a.draft_budget.default}.sum(&:amount);
  end

  def federal_allocated
    draft_budget_allocations.select{ |a| a.funding_source_type.try(:name) == "Federal"}.pluck(:amount).sum
  end

  def state_allocated
    draft_budget_allocations.select{ |a| a.funding_source_type.try(:name) == "State"}.pluck(:amount).sum
  end

  def local_allocated
    draft_budget_allocations.select{ |a| a.funding_source_type.try(:name) == "Local"}.pluck(:amount).sum
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

  def set_estimated_cost
    # If the phase cost has been manually updated, don't override it
    if !cost_estimated
      return
    end
    self.update(cost: estimated_cost)
  end

  def estimated_cost
    cost = 0
    transit_assets.each do |asset|
      cost += asset.estimated_replacement_cost_in_year self.fy_year 
    end
    return cost
  end

  def notional
    draft_project.try(:notional)
  end

  def copy new_project, pinned_only=false, starting_year=nil
    #Return if we want pinned phases only and this phase is not pinned
    if pinned_only and !pinned 
      return 
    end

    if starting_year and starting_year > fy_year 
      return 
    end

    attributes = {}
    (FORM_PARAMS - [:draft_project_id]).each do |param|
      attributes[param] = self.send(param)
    end   
    attributes[:draft_project] = new_project

    new_project_phase = DraftProjectPhase.create(attributes)
    new_project_phase.draft_funding_requests.each{ |dfr| dfr.destroy } #Delete the default funding request. take whateve the copy gives us

    # Copy over the DraftProjectPha
    draft_funding_requests.each do |dfr|
      dfr.copy(new_project_phase)
    end

    # Add all the Transit Assets
    new_project_phase.transit_assets << self.transit_assets 
  end

  #This orders the draft budget allocations by whether or not the draft budet's funding source type is
  # 1 Federal, 2 State, 3 Local, 4 Agency.
  # A better way to handle this may be to assign rankings to the templates, fundings sources, or funding source types.
  def ordered_allocations
    feds = []
    states = []
    locals = []
    agencies = [] 

    #TODO: Don't use names in logic.
    draft_budget_allocations.each do |alloc|
      case alloc.funding_source_type.try(:name)
      when "Federal"
        feds << alloc 
      when "State"
        states << alloc 
      when "Local"
        locals << alloc 
      when "Agency"
        agencies << alloc
      end

    end

    return [feds, states, locals, agencies].flatten

  end   

  def age_to_condition
    assets = self.transit_assets
    return assets.map{ |a| [a.age, a.reported_condition_rating] }
  end

  def age_to_mileage
    assets = self.transit_assets
    mileages = (assets.map{ |a| a.very_specific.try(:reported_mileage) }).compact #Compact is used to remove nil mileages
    
    if mileages.empty?
      return nil 
    end    

    avg=(mileages.reduce(:+) / mileages.size.to_f).round(2)
    data = []
    assets.each do |a|
      x = [a.age, a.very_specific.try(:reported_mileage)]
      unless x[1].nil?
        data.push(x)
      end
    end

    return [{name: "Mileages", data: data}];
  
  end

  def long_name
    "#{team_ali_code.try(:code)}: #{name} (#{self.fiscal_year(fy_year)})"
  end

  def parent_ali_code
    draft_project.team_ali_code
  end

  def milestones_completed?
    milestones.required.where(milestone_date: nil).empty?
  end 

  #TODO Don't use names in logic
  def federal_and_local_funding_complete?
    draft_budgets.where(default: true).each do |budget|
      if budget.funding_source_type.try(:name).in? ["Federal", "Local"]
        return false
      end
    end
    return true 
  end

  #TODO Don't use names in logic
  def state_funding_complete?
    draft_budgets.where(default: true).each do |budget|
      if budget.funding_source_type.try(:name).in? ["State"]
        return false
      end
    end
    return true 
  end

  def organization
    scenario.organization
  end

  def get_count
    count || transit_assets.count 
  end

  #------------------------------------------------------------------------------
  #
  # DotGrants Methods
  #
  #------------------------------------------------------------------------------

  def dotgrants_json
    export =  
      {
        activity_line_item: {
              id: id, 
              object_key: object_key,
              capital_project_id: draft_project.try(:id),
              fy_year: fy_year,
              team_ali_code_id: team_ali_code.id,
              name: name,
              anticipated_cost: cost,
              estimated_cost: estimated_cost,
              cost_justification: cost_justification,
              active: true,
              created_at: created_at,
              updated_at: updated_at,
              fuel_type_id: fuel_type.try(:id),
              is_planning_complete: is_planning_complete?,
              purchased_new: purchased_new?,
              count: get_count,
              length: length,
              team_ali_code: team_ali_code.try(:dotgrants_json),
              fuel_type: fuel_type.try(:dotgrants_json),
              capital_project: draft_project.try(:dotgrants_json),
              milestones: milestones.map{ |milestone| milestone.dotgrants_json},
              funding_requests: draft_funding_requests.map{ |fr| fr.dotgrants_json},
              assets: transit_assets.map{ |transit_asset| transit_asset.dotgrants_json}
        }
      }
    return export
  end

  def is_planning_complete?
    scenario.state == "approved" and scenario.fy_year >= fy_year 
  end

  def purchased_new?
    transit_assets.first.try(:purchased_new)
  end

  def length
    if transit_assets.count == 0
      return nil
    else
      return transit_assets.first.very_specific.try(:vehicle_length)
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

  private

  def add_milestones
    MilestoneType.active.each do |mt|
      Milestone.where(milestone_type: mt, draft_project_phase: self).first_or_create!
    end 
  end

  def add_funding_request
    DraftFundingRequest.create(draft_project_phase: self)
  end
end
