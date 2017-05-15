class CreateCapitalPlanModuleTypes < ActiveRecord::Migration
  def change
    create_table :capital_plan_module_types do |t|
      t.integer :capital_plan_type_id, index: true
      t.string :name
      t.string :class_name
      t.integer :sequence
      t.boolean :active
    end

    capital_plan_module_types = [
        {capital_plan_type_id: 1, name: 'Preparation', class_name: 'BaseCapitalPlanModule', sequence: 1, active: true},
        {capital_plan_type_id: 1, name: 'Unconstrained Plan', class_name: 'UnconstrainedCapitalPlanModule', sequence: 2, active: true},
        {capital_plan_type_id: 1, name: 'Constrained Plan', class_name: 'ConstrainedCapitalPlanModule', sequence: 3, active: true},
        {capital_plan_type_id: 1, name: 'Final Review', class_name: 'ReviewCapitalPlanModule', sequence: 4, active: true}
    ]

    capital_plan_module_types.each do |type|
      CapitalPlanModuleType.create!(type)
    end

  end
end
