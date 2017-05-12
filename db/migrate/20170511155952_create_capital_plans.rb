class CreateCapitalPlans < ActiveRecord::Migration
  def change
    create_table :capital_plans do |t|
      t.string :object_key, limit: 12
      t.integer :organization_id, index: true
      t.integer :fy_year

      t.timestamps
    end
  end
end
