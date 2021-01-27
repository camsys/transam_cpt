class AddDraftProjectToDraftProjectPhase < ActiveRecord::Migration[5.2]
  def change
    add_reference :draft_project_phases, :draft_project, foreign_key: true
  end
end
