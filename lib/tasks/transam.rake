namespace :transam do
  desc "Build SOGR projects from scratch"
  task :build_sogr_projects, [:org_short_name] => [:environment] do |t, args|
    org = TransitOperator.find_by(short_name: args[:org_short_name])
    orgs = org.nil? ? TransitOperator.all : [org]
    CapitalProject.where(organization: orgs).destroy_all

    orgs.each do |o|
      builder = CapitalProjectBuilder.new
      num_created = builder.build(o) # uses default options

      puts "#{num_created} SOGR capital projects were added to #{o.short_name}'s capital needs list."
    end
  end

  desc "Build Capital Plan Workflow"
  task build_capital_plan_structure: :environment do
    capital_plan_types = [
        {id: 1, name: 'Transit Capital Plan', description: 'Transit Capital Plan', active: true}
    ]
    capital_plan_module_types = [
        {id: 1, capital_plan_type_id: 1, name: 'Preparation', class_name: 'BaseCapitalPlanModule', strict_action_sequence: false, sequence: 1, active: true},
        {id: 2, capital_plan_type_id: 1, name: 'Unconstrained Plan', class_name: 'BaseCapitalPlanModule', strict_action_sequence: false, sequence: 2, active: true},
        {id: 3, capital_plan_type_id: 1, name: 'Constrained Plan', class_name: 'ConstrainedCapitalPlanModule', strict_action_sequence: false, sequence: 3, active: true},
        {id: 4, capital_plan_type_id: 1, name: 'Final Review', class_name: 'ReviewCapitalPlanModule', strict_action_sequence: true, sequence: 4, active: true}
    ]
    capital_plan_action_types = [
        {id: 1, capital_plan_type_id: 1, capital_plan_module_type_id: 1, name: 'Assets Updated', class_name: 'AssetPreparationCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},

        {id: 2, capital_plan_type_id: 1, capital_plan_module_type_id: 2, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {id: 3, capital_plan_type_id: 1, capital_plan_module_type_id: 2, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

        {id: 4, capital_plan_type_id: 1, capital_plan_module_type_id: 3, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {id: 5, capital_plan_type_id: 1, capital_plan_module_type_id: 3, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

        {id: 6, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Approver 1', class_name: 'BaseCapitalPlanAction', roles: 'approver_one', sequence: 1, active: true},
        {id: 7, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Approver 2', class_name: 'BaseCapitalPlanAction', roles: 'approver_two', sequence: 2, active: true},
        {id: 8, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Approver 3', class_name: 'BaseCapitalPlanAction', roles: 'approver_three', sequence: 3, active: true},
        {id: 9, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Approver 4', class_name: 'BaseCapitalPlanAction', roles: 'approver_four', sequence: 4, active: true},
        {id: 10, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Archive', class_name: 'BaseCapitalPlanAction', roles: 'admin', sequence: 4, active: true}
    ]

    CapitalPlanType.destroy_all
    CapitalPlanModuleType.destroy_all
    CapitalPlanActionType.destroy_all
    CapitalPlan.destroy_all

    plan_tables = %w{ capital_plan_types capital_plan_module_types capital_plan_action_types }

    plan_tables.each do |table_name|
      puts "  Loading #{table_name}"
      data = eval(table_name)
      klass = table_name.classify.constantize
      data.each do |row|
        x = klass.new(row)
        x.save!
      end
    end

    Organization.update_all(capital_plan_type_id: 1)
    ActivityLineItem.update_all(is_planning_complete: false)

    roles = [
        {name: 'approver_one', weight: 11, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 1'},
        {name: 'approver_two', weight: 12, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 2'},
        {name: 'approver_three', weight: 13, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 3'},
        {name: 'approver_four', weight: 14, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 4'},
    ]
    roles.each do |role|
      if Role.find_by(name: role[:name]).nil?
        Role.create!(role)
      end
    end
  end
end
