class AddCountToDraftProjectPhase < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_project_phases, :count, :integer
  end
end
