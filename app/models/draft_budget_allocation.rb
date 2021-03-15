class DraftBudgetAllocation < ApplicationRecord
  
  # Include the object key mixin
  include TransamObjectKey


  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :draft_funding_request
  has_one :draft_project_phase, through: :draft_funding_request
  belongs_to :draft_budget

  FORM_PARAMS = [
    :draft_budget_id,
    :draft_funding_request_id,
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

  def funding_source_type
    draft_budget.funding_source_type
  end

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  #validates :draft_project_phase, presence: true 
  #validates :draft_budget, presence: true
  #validates :amount, presence: true

end
