class AddCostEstimatedToDraftProjectPhase < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_project_phases, :cost_estimated, :boolean, default: :true
  end
end
