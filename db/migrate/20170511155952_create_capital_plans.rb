class CreateCapitalPlans < ActiveRecord::Migration[4.2]
  def change
    create_table :capital_plans do |t|
      t.string :object_key, limit: 12
      t.integer :capital_plan_type_id, index: true
      t.integer :organization_id, index: true
      t.integer :fy_year

      t.timestamps
    end
  end
end
