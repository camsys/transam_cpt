class DraftProjectDistrict < ApplicationRecord

  # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  FORM_PARAMS = [
    :draft_project_id,
    :district_id
  ]

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :draft_project
  belongs_to :district

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  validates :draft_project_id, presence: true 
  validates :district_id, presence: true

end
