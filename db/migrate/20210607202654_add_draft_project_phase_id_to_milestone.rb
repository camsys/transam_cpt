class AddDraftProjectPhaseIdToMilestone < ActiveRecord::Migration[5.2]
  def change
  	add_reference :milestones, :draft_project_phase, index: true
  end
end
