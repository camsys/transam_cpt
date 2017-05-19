class CreateCapitalPlanActionTypes < ActiveRecord::Migration
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

    capital_plan_action_types = [
        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Preparation').id, name: 'Assets Updated', class_name: 'AssetPreparationCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Preparation').id, name: 'Funding Verified', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 2, active: true},

        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Unconstrained Plan').id, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Unconstrained Plan').id, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Constrained Plan').id, name: 'Funding Complete', class_name: 'FundingCompleteConstrainedCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Constrained Plan').id, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 2, active: true},
        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Constrained Plan').id, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 3, active: true},

        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Final Review').id, name: 'Approver 1', class_name: 'BaseCapitalPlanAction', roles: 'approver_one', sequence: 1, active: true},
        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Final Review').id, name: 'Approver 2', class_name: 'BaseCapitalPlanAction', roles: 'approver_two', sequence: 2, active: true},
        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Final Review').id, name: 'Approver 3', class_name: 'BaseCapitalPlanAction', roles: 'approver_three', sequence: 3, active: true},
        {capital_plan_type_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Final Review').id, name: 'Approver 4', class_name: 'BaseCapitalPlanAction', roles: 'approver_four', sequence: 4, active: true}
    ]

    roles = [
        {name: 'approver_one', weight: 11, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 1'},
        {name: 'approver_two', weight: 12, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 2'},
        {name: 'approver_three', weight: 13, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 3'},
        {name: 'approver_four', weight: 14, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 4'},
    ]

    capital_plan_action_types.each do |type|
      CapitalPlanActionType.create!(type)
    end

    roles.each do |role|
      Role.create!(role)
    end
  end
end
