class DraftBudget < ApplicationRecord

   # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  FORM_PARAMS = [
    :name,
    :amount,
    :funding_template_id
  ]

  validates :name, presence: true 
  validates :funding_template_id, presence: true
  validates :amount, presence: true 

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  has_many :draft_budget_allocations
  has_many :draft_funding_requests, through: :draft_budget_allocations
  has_many :draft_project_phases, through: :draft_funding_requests
  
  belongs_to :funding_template
  has_one    :funding_source, through: :funding_template
  has_one :funding_source_type, through: :funding_source

  #------------------------------------------------------------------------------
  # Instance Methods
  #------------------------------------------------------------------------------
  def allocated
    draft_budget_allocations.pluck(:amount).sum
  end

  def remaining
    amount - allocated
  end

  #Federal/State/Local/Agency
  def funding_source_type
    funding_template.funding_source_type 
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
