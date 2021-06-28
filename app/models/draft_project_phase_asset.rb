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
  # Case 1: A Phase already exists that matches the asset, so add the asset to that phase.
  # Case 2: A Phase does NOT exist, create a new phase and create a new project for that phase.
  def move_to year

    old_phase = self.draft_project_phase 
    old_project = self.draft_project

    #########################################
    if transit_asset.fuel_type_id.present?
      phase = scenario.draft_project_phases.where(team_ali_code: draft_project_phase.team_ali_code, fy_year: year, fuel_type: asset.fuel_type).first
    else
      phase = scenario.draft_project_phases.where(team_ali_code: draft_project_phase.team_ali_code, fy_year: year).first
    end

    if phase.nil?
      #We don't have a phase. let's create a new project and a new phase for this asset
      new_project = old_project.copy_from_attributes 
      phase = DraftProjectPhase.new 
      phase.team_ali_code = old_phase.team_ali_code
      phase.fy_year = year
      fuel_type = asset.fuel_type if transit_asset.fuel_type_id.present?
      phase.cost = -1 
      phase.name = new_project.title 
      phase.draft_project = new_project
      phase.save!
      new_project.set_project_number
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
