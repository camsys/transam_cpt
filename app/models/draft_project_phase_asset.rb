class DraftProjectPhaseAsset < ApplicationRecord
 
  # Include the object key mixin
  include TransamObjectKey

  FORM_PARAMS = [
    :draft_project_phase_id,
    :transit_asset_id
  ]

  belongs_to :draft_project_phase
  belongs_to :transit_asset

  has_one :draft_project, through: :draft_project_phase 
  has_one :scenario, through: :draft_project

  #Move this Asset to another year.
  # 1) Check to see if a phase already exists.
  # 2) If no phase exists, create a new one
  # 3) Reassign this asset to that hpase
  def move_to year

    old_phase = self.draft_project_phase 

    #########################################
    if transit_asset.fuel_type_id.present?
      phase = DraftProjectPhase.where(draft_project: draft_project, team_ali_code: draft_project_phase.team_ali_code, fy_year: year, fuel_type: asset.fuel_type).first_or_initialize do |phase|
        phase.name = draft_project.title
        phase.cost = -1
      end
    else
      phase = DraftProjectPhase.where(draft_project: draft_project, team_ali_code: draft_project_phase.team_ali_code, fy_year: year).first_or_initialize do |phase|
        phase.name = draft_project.title
        phase.cost = -1
      end
    end

    self.draft_project_phase = phase 
    self.save 
    self.draft_project_phase.set_estimated_cost
    old_phase.set_estimated_cost


  end

  def replacement_year
    draft_project_phase.try(:fy_year)
  end

   #------------------------------------------------------------------------------
  def self.allowable_params
    FORM_PARAMS
  end
end
