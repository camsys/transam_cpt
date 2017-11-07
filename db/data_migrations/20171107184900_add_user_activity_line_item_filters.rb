class AddUserActivityLineItemFilters < ActiveRecord::DataMigration
  def up
    sys_user = User.find_by_first_name('system')
    filters = [
        {name: 'All ALIs', description: "All ALIs within your org filter", sogr_type: 'All'},
        {name: 'Vehicles', description: 'Revenue and Support Vehicles', asset_types: AssetType.where(class_name: ['Vehicle', 'SupportVehicle']).pluck(:id).join(',')},
        {name: 'Equipment', description: 'Maintenance, IT, Facility, Office, or Communications Equipment, and Signals/Signs', asset_types: AssetType.where(class_name: 'Equipment').pluck(:id).join(',')},
        {name:'Facilities', description: 'Transit and Support Facilities', asset_types: AssetType.where(class_name: ['TransitFacility', 'SupportFacility']).pluck(:id).join(',')},
        {name: 'Rail and Locomotive', description: 'Rail and Locomotive', asset_types: AssetType.where(class_name: ['RailCar', 'Locomotive']).pluck(:id).join(',')},
        {name: 'Backlog Assets', description: 'ALIS with assets in Backlog', in_backlog: true},
        {name: 'Planning Year ALIs', description: 'ALIs in this planning fiscal year', planning_year: true},
        {name: 'Shared Ride Assets', description: 'ALIS with assets with FTA Mode Type Demand Response', asset_query_string: Asset.joins('INNER JOIN assets_fta_mode_types ON assets.id = assets_fta_mode_types.asset_id').where('assets_fta_mode_types.fta_mode_type_id = ?', FtaModeType.find_by(name: 'Demand Response').id).to_sql},
        {name: 'Agency Funded', description: 'ALIs funded with agency owned funds', funding_bucket_query_string: FundingBucket.agency_owned(nil).to_sql}
    ]

    # Remove all previous system filters
    QueryParam.where(class_name: 'UserActivityLineItemFilter').destroy_all
    UserActivityLineItemFilter.destroy_all

    # Create each one, row by row
    filters.each do |h|
      QueryParam.find_or_create_by(name: h[:name], description: h[:description], query_string: h[:asset_query_string] || h[:funding_bucket_query_string], class_name: 'UserActivityLineItemFilter', active: true) if h[:asset_query_string] || h[:funding_bucket_query_string]
      f = UserActivityLineItemFilter.new(h)
      f.users = User.all
      f.creator = sys_user
      f.save!
    end

    User.all.update_all(user_activity_line_item_filter_id: UserActivityLineItemFilter.find_by(name: 'All ALIs').id)
  end
end