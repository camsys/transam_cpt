class CreateScenarios < ActiveRecord::Migration[5.2]
  def change
    create_table :scenarios do |t|
      t.string :object_key, limit: 12
      t.integer :organization_id, index: true
      t.integer :fy_year

      t.timestamps
    end
  end
end
