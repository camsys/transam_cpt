class DraftProject < ApplicationRecord

   # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  FORM_PARAMS = [
    :project_number,
    :title,
    :description,
    :justification,
    :team_ali_code_id,
    :notional,
    :fy_year,
    :scenario_id,
    :capital_project_type_id,
    :sogr,
    :emergency
  ]

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :scenario
  belongs_to :team_ali_code
  belongs_to :capital_project_type
  has_many :draft_project_phases, :dependent => :destroy
  has_many :draft_project_districts, :dependent => :destroy
  has_many :districts, through: :draft_project_districts

  alias phases draft_project_phases #just to save on typing

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :team_ali_code_id, presence: true

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

  def copy(new_scenario, pinned_only=false, starting_year=nil)
    
    #Return if we want pinned phases only and this project has none
    if pinned_only and !has_pinned_phases? starting_year
      return 
    end

    #REturn if this project as no ALIs  at or beyond the starting year
    if starting_year and !has_projects_beyond_year? starting_year 
      return 
    end   

    attributes = {}
    (FORM_PARAMS - [:scenario_id]).each do |param|
      attributes[param] = self.send(param)
    end   
    attributes[:scenario] = new_scenario

    new_project = DraftProject.create(attributes)

    # Copy over the DraftProjectPhases and the Children of Draft Project Phases
    draft_project_phases.each do |dpp|
      dpp.copy(new_project, pinned_only, starting_year)
    end
  end

  def has_pinned_phases? starting_year=nil
    if starting_year
      draft_project_phases.where(pinned: true).where('fy_year >= ?', starting_year).count > 0
    else
      draft_project_phases.where(pinned: true).where.count > 0
    end
  end

  def has_projects_beyond_year? starting_year
    draft_project_phases.where('fy_year >= ?', starting_year).count > 0
  end

  #------------------------------------------------------------------------------
  # DotGrants Export
  #------------------------------------------------------------------------------
  def dotgrants_json
    {
      id: id,
      object_key: object_key,
      fy_year: fy_year,
      project_number: project_number,
      organization_id: organization_id,
      team_ali_code_id: team_ali_code_id,
      capital_project_type_id: capital_project_type_id,
      notional: notional,
      multi_year: multi_year?,
      state: scenario.state,
      sogr: sogr,
      title: title,
      description: description,
      justification: justification,
      active: true,
      created_at: created_at,
      updated_at: updated_at,
      emergency: emergency,
      organization: scenario.try(:organization).try(:dotgrants_json),
      capital_project_type: capital_project_type.try(:dotgrants_json),
      team_ali_code: team_ali_code.try(:dotgrants_json)
    }
  end

  def fy_year
    phases.pluck(:fy_year).min.to_i
  end

  def multi_year?
    phases.pluck(:fy_year).max.to_i > fy_year 
  end

  def organization_id
    scenario.try(:organization).try(:id)
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

  def year_to_cost
    d = {}
    self.year_range.each do |year|
      d[year] = phases.select { |phase| phase.fy_year == year }.sum { |phase| phase.cost }
    end
    return d
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
