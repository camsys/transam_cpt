class DraftFundingRequest < ApplicationRecord
  
  # Include the object key mixin
  include TransamObjectKey
  
  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :draft_project_phase
  has_many :draft_budget_allocations, dependent: :destroy
  has_many :draft_budgets, through: :draft_budget_allocations

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


  def effective_pct allocation
    remaining_pct = 1.0
    self.ordered_allocations.each do |alloc|
      effective_pct = alloc.required_pct * remaining_pct
      remaining_pct = remaining_pct - effective_pct
      if alloc == allocation 
        return effective_pct
      end
    end
  end

  def lock_total total
    accumulated = 0.0
    self.ordered_allocations.each do |alloc|
      calc_amount = (alloc.effective_pct.to_f * total.to_f).floor()
      if(alloc.required_pct == 1.0)
        alloc.amount = total - accumulated
      else
        alloc.amount = calc_amount
      end
      accumulated += calc_amount
      alloc.save!
    end
  end

  #------------------------------------------------------------------------------
  # Instance Methods
  #------------------------------------------------------------------------------
  def total
    draft_budget_allocations.pluck(:amount).sum
  end

  #------------------------------------------------------------------------------
  # Business Rules
  #------------------------------------------------------------------------------

  def violations
    return at_most_one_funding_source_type_per_request
  end

  def at_most_one_funding_source_type_per_request
    types = []
    messages  = []
    ordered_allocations.each do |dba|
      if dba.funding_source_type.in? types
        messages << "More than one #{dba.funding_source_type.try(:name)} Funding Source is not permitted."
      else
        types << dba.funding_source_type
      end
    end

    return messages.uniq 
  
  end

end
