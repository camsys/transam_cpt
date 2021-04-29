class DraftProjectPhaseAsset < ApplicationRecord
  belongs_to :draft_project_phase
  belongs_to :transit_asset
end
