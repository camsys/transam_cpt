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
    :scenario_id
  ]

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :scenario
  belongs_to :team_ali_code
  has_many :draft_project_phases, :dependent => :destroy

  alias phases draft_project_phases #just to save on typing

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

  def copy new_scenario
    attributes = {}
    (FORM_PARAMS - [:scenario_id]).each do |param|
      attributes[param] = self.send(param)
    end   
    attributes[:scenario] = new_scenario

    new_project = DraftProject.create(attributes)

    # Copy over the DraftProjectPhases and the Children of Draft Project Phases
    draft_project_phases.each do |dpp|
      dpp.copy(new_project)
    end
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
