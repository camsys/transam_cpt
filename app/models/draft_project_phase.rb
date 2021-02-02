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

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
  def self.allowable_params
    FORM_PARAMS
  end
end
