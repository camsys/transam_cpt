class CreateDraftProjectPhases < ActiveRecord::Migration[5.2]
  def change
    create_table :draft_project_phases do |t|
      t.string :object_key, limit: 12
      t.string :name
      t.integer :cost
      t.integer :fy_year
      t.text :justification

      t.timestamps
    end
  end
end
