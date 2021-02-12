class DraftBudgetAllocation < ApplicationRecord
  
  # Include the object key mixin
  include TransamObjectKey

  belongs_to :draft_project_phase
  belongs_to :draft_budget

  FORM_PARAMS = [
    :draft_budget_id,
    :draft_project_phase_id,
    :amount
  ]

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
  def self.allowable_params
    FORM_PARAMS
  end


  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  #validates :draft_project_phase, presence: true 
  #validates :draft_budget, presence: true
  #validates :amount, presence: true
end
