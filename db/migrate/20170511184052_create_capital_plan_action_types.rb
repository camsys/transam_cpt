class CreateCapitalPlanActionTypes < ActiveRecord::Migration
  def change
    create_table :capital_plan_action_types do |t|
      t.integer :capital_plan_id, index: true
      t.integer :capital_plan_module_id, index: true
      t.string :name
      t.string :class_name
      t.integer :sequence
      t.boolean :active
    end

    capital_plan_action_types = [
        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Preparation').id, name: 'Assets Updated', class_name: 'AssetPreparationCapitalPlanAction', sequence: 1, active: true},
        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Preparation').id, name: 'Funding Verified', class_name: 'FundingPreparationCapitalPlanAction', sequence: 2, active: true},

        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Unconstrained Plan').id, name: 'Agency Approval', class_name: 'AgencyApprovalUnconstrainedCapitalPlanAction', sequence: 1, active: true},
        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Unconstrained Plan').id, name: 'State Approval', class_name: 'StateApprovalUnconstrainedCapitalPlanAction', sequence: 2, active: true},

        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Constrained Plan').id, name: 'Agency Approval', class_name: 'AgencyApprovalConstrainedCapitalPlanAction', sequence: 1, active: true},
        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType.find_by(name: 'Constrained Plan').id, name: 'State Approval', class_name: 'StateApprovalConstrainedCapitalPlanAction', sequence: 2, active: true},

        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType(name: 'Final Review').id, name: 'Approver 1', class_name: 'ReviewCapitalPlanAction', sequence: 4, active: true},
        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType(name: 'Final Review').id, name: 'Approver 2', class_name: 'ReviewCapitalPlanAction', sequence: 4, active: true},
        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType(name: 'Final Review').id, name: 'Approver 3', class_name: 'ReviewCapitalPlanAction', sequence: 4, active: true},
        {capital_plan_id: 1, capital_plan_module_type_id: CapitalPlanModuleType(name: 'Final Review').id, name: 'Approver 4', class_name: 'ReviewCapitalPlanAction', sequence: 4, active: true}
    ]

    capital_plan_action_types.each do |type|
      CapitalPlanActionType.create!(type)
    end
  end
end
