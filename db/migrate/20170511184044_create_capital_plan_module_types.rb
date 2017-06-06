class CreateCapitalPlanModuleTypes < ActiveRecord::Migration
  def change
    create_table :capital_plan_module_types do |t|
      t.integer :capital_plan_type_id, index: true
      t.string :name
      t.string :class_name
      t.boolean :strict_action_sequence
      t.integer :sequence
      t.boolean :active
    end

  end
end
