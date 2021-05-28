class AddPinnedToDraftProjectPhase < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_project_phases, :pinned, :boolean, default: :false
  end
end
