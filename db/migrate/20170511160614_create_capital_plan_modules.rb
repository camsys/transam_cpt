class CreateCapitalPlanModules < ActiveRecord::Migration[4.2]
  def change
    create_table :capital_plan_modules do |t|
      t.string :object_key, limit: 12
      t.integer :capital_plan_id, index: true
      t.integer :capital_plan_module_type_id, index: true
      t.integer :sequence
      t.datetime :completed_at
      t.integer :completed_by_user_id

      t.timestamps
    end
  end
end
