class DraftBudgetAllocation < ApplicationRecord
  
  # Include the object key mixin
  include TransamObjectKey

  belongs_to :draft_project_phase
  belongs_to :draft_budget

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  #validates :draft_project_phase, presence: true 
  #validates :draft_budget, presence: true
  #validates :amount, presence: true
end
