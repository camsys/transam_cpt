class CreateCapitalPlanActionTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :capital_plan_action_types do |t|
      t.integer :capital_plan_type_id, index: true
      t.integer :capital_plan_module_type_id, index: true
      t.string :name
      t.string :class_name
      t.string :roles
      t.integer :sequence
      t.boolean :active
    end
  end
end
