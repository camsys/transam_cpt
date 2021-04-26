class DraftProjectPhaseAsset < ApplicationRecord
 
  # Include the object key mixin
  include TransamObjectKey

  belongs_to :draft_project_phase
  belongs_to :transit_asset

  has_one :draft_project, through: :draft_project_phase 
  has_one :scenario, through: :draft_project
end
