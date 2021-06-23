class RenamJustificationiCostJutification < ActiveRecord::Migration[5.2]
  def change
  	rename_column :draft_project_phases, :justification, :cost_justification
  end
end
