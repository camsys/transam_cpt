class AddTeamAliCodeToDraftPhase < ActiveRecord::Migration[5.2]
  def change
    add_reference :draft_projects, :team_ali_code, foreign_key: true, type: :bigint
    add_reference :draft_project_phases, :team_ali_code, foreign_key: true, type: :bigint
  end
end
