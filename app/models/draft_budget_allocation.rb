class DraftBudgetAllocation < ApplicationRecord
  
  # Include the object key mixin
  include TransamObjectKey


  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :draft_funding_request
  has_one :draft_project_phase, through: :draft_funding_request
  has_one :draft_project, through: :draft_project_phase
  has_one :scenario, through: :draft_project
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


  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  def funding_source_type
    draft_budget.funding_source_type
  end

  def effective_pct
    draft_funding_request.effective_pct(self)
  end
  
  def required_pct
    draft_budget.funding_template.match_required / 100
  end

  def copy new_funding_request
    attributes = {}
    (FORM_PARAMS - [:draft_funding_request_id]).each do |param|
      attributes[param] = self.send(param)
    end   
    attributes[:draft_funding_request] = new_funding_request

    DraftBudgetAllocation.create(attributes)
  end

  #------------------------------------------------------------------------------
  # Dotgrants JSON
  #------------------------------------------------------------------------------
  def dotgrants_json
    {
      id: id,
      object_key: object_key,
      funding_template_id: draft_budget.try(:funding_template_id),
      fy_year: draft_project_phase.try(:fy_year),
      name: draft_budget.try(:name),
      budget_amount: draft_budget.try(:amount),
      budget_committed: draft_budget.try(:allocated),
      owner_id: draft_budget.try(:owner_id),
      description: nil,
      active: draft_budget.try(:active),
      created_by_id: nil,
      updated_by_id: nil,
      created_at: draft_budget.try(:created_at),
      updated_at: draft_budget.try(:updated_at),
      line_num: nil,
      act_num: nil, 
      pt_num: nil,
      grantee_code: nil,
      page_num: nil, 
      item_num: nil, 
      bond_request_id: nil,
      target_organization_id: nil,
      funding_template: draft_budget.try(:funding_template).try(:dotgrants_json)
    }
  end

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :draft_project_phase, presence: true 
  validates :draft_budget, presence: true
  validates :amount, presence: true

end
