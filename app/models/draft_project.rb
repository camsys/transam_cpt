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
    :scenario_id,
    :capital_project_type_id,
    :sogr,
    :emergency
    #:district_ids => []
  ]

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :scenario
  has_one :organization, through: :scenario
  belongs_to :team_ali_code
  belongs_to :capital_project_type
  has_many :draft_project_phases, :dependent => :destroy
  has_many :draft_project_phase_assets, through: :draft_project_phases 
  has_many :transit_assets, through: :draft_project_phase_assets
  has_many :draft_project_districts, :dependent => :destroy
  has_many :districts, through: :draft_project_districts

  alias phases draft_project_phases #just to save on typing

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :team_ali_code_id, presence: true
  validates :project_number, presence: true

  #------------------------------------------------------------------------------
  # Instance Methods
  #------------------------------------------------------------------------------
  def cost
     phases.pluck(:cost).sum
  end 

  def allocated
    phases.map{ |phase| phase.allocated }.sum
  end

  def federal_allocated
    phases.map{ |p| p.draft_budget_allocations.select{ |a| a.funding_source_type.try(:name) == "Federal"}.pluck(:amount).sum}.sum
  end

  def state_allocated
    phases.map{ |p| p.draft_budget_allocations.select{ |a| a.funding_source_type.try(:name) == "State"}.pluck(:amount).sum}.sum
  end

  def local_allocated
    phases.map{ |p| p.draft_budget_allocations.select{ |a| a.funding_source_type.try(:name) == "Local"}.pluck(:amount).sum}.sum
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
    (FORM_PARAMS - [:scenario_id, {district_ids: [] }]).each do |param|
      attributes[param] = self.send(param)
    end   
    attributes[:scenario] = new_scenario

    new_project = DraftProject.create(attributes)
    new_project.districts = self.districts

    # Copy over the DraftProjectPhases and the Children of Draft Project Phases
    draft_project_phases.each do |dpp|
      dpp.copy(new_project, pinned_only, starting_year)
    end
  end

  def copy_from_attributes 
    attributes = {}
    FORM_PARAMS.each do |param|
      attributes[param] = self.send(param)
    end   
    new_project = DraftProject.create(attributes)
    new_project.districts = self.districts
    new_project.save!
    return new_project
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

  def set_project_number
    years = fiscal_year self.fy_year
    org_short_name = scenario.try(:organization).try(:short_name)
    project_number = "#{org_short_name} #{years} ##{id}"
    self.update_attributes(:project_number => project_number)
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
      team_ali_code: team_ali_code.try(:dotgrants_json),
      districts: districts.map{ |district| district.try(:dotgrants_json) }
    }
  end

  # check if project has any early replacement assets
  def has_early_replacement_assets?
    sogr? && !notional? && !transit_assets.joins(:transam_asset).where("policy_replacement_year is not NULL and scheduled_replacement_year is not NULL and scheduled_replacement_year < policy_replacement_year").empty?
  end

  # Render the project as a JSON object -- overrides the default json encoding
  def as_json(options={})
    # Don't override Rails method
    if options[:is_super]
      if options[:root]
        {"capital_project" => (super(options)['capital_project'].merge! self.fundable_as_json)}
      else
        super(options)
      end
    else
      json = {
        object_key: object_key,
        scenario: scenario.name,
        agency: organization.try(:to_s),
        fy_year: formatted_fiscal_year,
        project_number: project_number,
        primary_scenario: scenario.try(:primary_scenario),
        scope: team_ali_code.try(:scope),
        is_emergency: emergency?,
        is_sogr: sogr?,
        is_notional: notional?,
        is_multi_year: multi_year?,
        type: capital_project_type.try(:code),
        title: title,
        total_cost: cost,
        has_early_replacement_assets: has_early_replacement_assets?,
        scenario_created: scenario.try(:created_at),
        scenario_modified: scenario.try(:updated_at),
        description: description,
        justification: justification,
        number_of_alis: number_of_alis,
        number_of_assets: number_of_assets,
        scenario_status: scenario.try(:state_title)
      }


      if self.respond_to? :fundable_as_json
        json.merge! self.fundable_as_json(options)
      end

      json
    end
  end

  def self.to_csv scenarios
    attributes = 
                {
                  "Org": "organization_short_name",
                  "FY": "formatted_fiscal_year",
                  "Project": "project_number",
                  "Primary Scenario": "primary_scenario",
                  "Title": "title",
                  "Scope": "scope",
                  "Cost": "cost",
                  "# ALIs": "number_of_alis",
                  "# Assets": "number_of_assets",
                  "Type": "project_type_code",
                  "Emgcy": "emergency_code",
                  "SOGR": "sogr_code",
                  "Shadow": "shadow_code",
                  "Multi Year": "multi_year_code"
                }

    CSV.generate(headers: true) do |csv|
      csv << attributes.keys

      DraftProject.where(scenario_id: scenarios.pluck(:id)).each do |project|
        csv << attributes.values.map{ |attr| project.send(attr) }
      end
    end
  end

  def organization_short_name
    scenario.try(:organization).try(:short_name)
  end

  def fy_year
    phases.pluck(:fy_year).min.to_i
  end

  def scope
    team_ali_code.try(:scope)
  end

  def number_of_alis
    draft_project_phases.count 
  end

  def number_of_assets
    transit_assets.count
  end

  def project_type_code 
    capital_project_type.try(:code)
  end

  def emergency_code
    emergency ? "Y" : ""
  end

  def sogr_code
    sogr ? "Y" : ""
  end

  def shadow_code 
    notional ? "Y" : ""
  end

  def multi_year_code 
    multi_year? ? "Y" : ""
  end

  def multi_year?
    phases.pluck(:fy_year).max.to_i > fy_year 
  end

  def organization_id
    scenario.try(:organization).try(:id)
  end

  def formatted_fiscal_year
    fiscal_year(self.try(:fy_year))
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
