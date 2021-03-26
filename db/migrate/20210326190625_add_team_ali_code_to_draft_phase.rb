class AddTeamAliCodeToDraftPhase < ActiveRecord::Migration[5.2]
  def change
    add_reference :draft_projects, :team_ali_code, foreign_key: true, type: :integer
    add_reference :draft_project_phases, :team_ali_code, foreign_key: true, type: :integer
  end
end
