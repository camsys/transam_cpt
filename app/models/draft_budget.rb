class DraftBudget < ApplicationRecord

   # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  FORM_PARAMS = [
    :name,
    :amount
  ]

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  has_many :draft_budget_allocations
  has_many :draft_project_phases, through: :draft_budget_allocations

  #------------------------------------------------------------------------------
  # Instance Methods
  #------------------------------------------------------------------------------
  def allocated
    draft_budget_allocations.pluck(:amount).sum
  end

  def remaining
    amount - allocated
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
