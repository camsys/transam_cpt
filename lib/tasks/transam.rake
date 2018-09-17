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
        {id: 2, capital_plan_type_id: 1, capital_plan_module_type_id: 1, name: 'Updates OK', class_name: 'AssetOverridePreparationCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

        {id: 3, capital_plan_type_id: 1, capital_plan_module_type_id: 2, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {id: 4, capital_plan_type_id: 1, capital_plan_module_type_id: 2, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

        {id: 5, capital_plan_type_id: 1, capital_plan_module_type_id: 3, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {id: 6, capital_plan_type_id: 1, capital_plan_module_type_id: 3, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

        {id: 7, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Approver 1', class_name: 'BaseCapitalPlanAction', roles: 'approver_one', sequence: 1, active: true},
        {id: 8, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Approver 2', class_name: 'BaseCapitalPlanAction', roles: 'approver_two', sequence: 2, active: true},
        {id: 9, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Approver 3', class_name: 'BaseCapitalPlanAction', roles: 'approver_three', sequence: 3, active: true},
        {id: 10, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Approver 4', class_name: 'BaseCapitalPlanAction', roles: 'approver_four', sequence: 4, active: true},
        {id: 11, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Archive', class_name: 'BaseCapitalPlanAction', roles: 'admin', sequence: 4, active: true}
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

  desc "Add ALI filters"
  task add_user_activity_line_item_filters: :environment do
    asset_klass = Rails.application.config.asset_base_class_name.constantize

    sys_user = User.find_by_first_name('system')
    filters = [
        {name: 'All ALIs', description: "All ALIs within your org filter", sogr_type: 'All'},
        {name: 'Revenue Vehicles', description: 'Revenue Vehicles', asset_types: AssetType.where(class_name: ['Vehicle', 'SupportVehicle', 'RailCar', 'Locomotive']).pluck(:id).join(','), fta_asset_classes: FtaAssetClass.where(fta_asset_category: FtaAssetCategory.find_by(name: 'Revenue Vehicles')).pluck(:id).join(',')},
        {name: 'Equipment', description: 'Maintenance, IT, Facility, Office, or Communications Equipment, and Signals/Signs', asset_types: AssetType.where(class_name: 'Equipment').pluck(:id).join(','), fta_asset_classes: FtaAssetClass.where(fta_asset_category: FtaAssetCategory.find_by(name: 'Equipment')).pluck(:id).join(',')},
        {name:'Facilities', description: 'Transit and Support Facilities', asset_types: AssetType.where(class_name: ['TransitFacility', 'SupportFacility']).pluck(:id).join(','), fta_asset_classes: FtaAssetClass.where(fta_asset_category: FtaAssetCategory.find_by(name: 'Facilities')).pluck(:id).join(',')},
        {name: 'Backlog Assets', description: 'ALIS with assets in Backlog', in_backlog: true},
        {name: 'Planning Year ALIs', description: 'ALIs in this planning fiscal year', planning_year: true},
        {name: 'Shared Ride Assets', description: 'ALIS with assets with FTA Mode Type Demand Response', asset_query_string: asset_klass.joins("INNER JOIN assets_fta_mode_types ON #{asset_klass.table_name}.id = assets_fta_mode_types.#{asset_klass.to_s.foreign_key}").where('assets_fta_mode_types.fta_mode_type_id = ?', FtaModeType.find_by(name: 'Demand Response').id).to_sql}
    ]

    # Remove all previous system filters
    QueryParam.where(class_name: 'UserActivityLineItemFilter').destroy_all
    UserActivityLineItemFilter.destroy_all

    # Create each one, row by row
    filters.each do |h|
      QueryParam.find_or_create_by(name: h[:name], description: h[:description], query_string: h[:asset_query_string], class_name: 'UserActivityLineItemFilter', active: true) if h[:asset_query_string]
      f = UserActivityLineItemFilter.new(h)
      f.users = User.all
      f.creator = sys_user
      f.save!
    end

    User.all.update_all(user_activity_line_item_filter_id: UserActivityLineItemFilter.find_by(name: 'All ALIs').id)
  end
end
