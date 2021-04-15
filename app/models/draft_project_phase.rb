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
    :draft_project_id
  ]

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :draft_project
  belongs_to :team_ali_code
  belongs_to :fuel_type
  has_many :draft_funding_requests, :dependent => :destroy
  has_many :draft_budget_allocations, through: :draft_funding_requests
  has_many :draft_budgets, through: :draft_budget_allocations
  has_many :draft_project_phase_assets, :dependent => :destroy
  has_many :transit_assets, through: :draft_project_phase_assets

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
    # high=[]
    # med=[]
    # low=[]
    # assets.map{ |a| 
    #   x = [a.age, a.reported_condition_rating]
    #   if (a.reported_condition_rating < 1.67) 
    #     low.push(x)
    #   elsif (a.reported_condition_rating < 3.34) 
    #     med.push(x)
    #   else
    #     high.push(x)
    #   end
    # }
    # return [{name:"3.34-5.0", data:high}, {name:"1.67-3.33", data:med}, {name:"0.0-1.67", data:low}];
    return assets.map{ |a| {name: a.asset_tag, data:[[a.age, a.reported_condition_rating]], color:"blue"} }
  end

  def age_to_mileage
    assets = self.transit_assets
    milages = assets.map{ |a| a.very_specific.reported_mileage || 0 }
    avg=(milages.reduce(:+) / milages.size.to_f).round(2)
    above=[]
    below=[]
    assets.map{ |a| 
      x = [a.age, a.very_specific.reported_mileage]
      if (a.very_specific.reported_mileage < avg) 
        below.push(x)
      else
        above.push(x)
      end
    }
    return [{name:"Above Average", data:above}, {name:"Below Average", data:below}];
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
