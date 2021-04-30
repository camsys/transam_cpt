class AddObjectKeyToDraftProjectPhaseAsset < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_project_phase_assets, :object_key, :string, limit: 12
  end
end
