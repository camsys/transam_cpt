class DraftProject < ApplicationRecord

   # Include the object key mixin
  include TransamObjectKey

  # Include the fiscal year mixin
  include FiscalYear

  FORM_PARAMS = [
    :project_number,
    :title,
    :description,
    :justification
  ]

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------
  belongs_to :scenario

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------
  def self.allowable_params
    FORM_PARAMS
  end
end
