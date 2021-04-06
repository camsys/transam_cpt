class CreateDraftProjectPhaseAssets < ActiveRecord::Migration[5.2]
  def change
    create_table :draft_project_phase_assets do |t|
      t.references :draft_project_phase, index: true, foreign_key: true
      t.references :transit_asset, index: true, foreign_key: true
      t.timestamps
    end
  end
end
