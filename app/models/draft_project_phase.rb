class DraftProjectPhase < ApplicationRecord

  # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  FORM_PARAMS = [
    :name,
    :cost,
    :fy_year,
    :justification,
    :draft_project_id,
    :team_ali_code_id,
    :fuel_type_id,
    :pinned
  ]

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

  def remaining
    cost - allocated
  end

  def percent_funded
    return 0 if cost == 0
    return (100*(allocated.to_f/cost.to_f)).round
  end

  def set_estimated_cost
    self.update(cost: self.transit_assets.sum(:scheduled_replacement_cost))
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

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
  def self.allowable_params
    FORM_PARAMS
  end

  #private

  def add_milestones
    MilestoneType.active.each do |mt|
      Milestone.where(milestone_type: mt, draft_project_phase: self).first_or_create!
    end 
  end
end
