class AddFtaAssetClassesUserActivityLineItemFilters < ActiveRecord::DataMigration
  def up
    # cleanup ALI filters to use FTA asset category
    UserActivityLineItemFilter.find_by(name: 'Vehicles').update!(asset_types: AssetType.where(class_name: ['Vehicle', 'SupportVehicle', 'RailCar', 'Locomotive']).pluck(:id).join(','), fta_asset_classes: FtaAssetClass.where(fta_asset_category: FtaAssetCategory.find_by(name: 'Revenue Vehicles')).pluck(:id).join(','), name: 'Revenue Vehicles', description: 'Revenue Vehicles')
    UserActivityLineItemFilter.find_by(name: 'Equipment').update!(fta_asset_classes: FtaAssetClass.where(fta_asset_category: FtaAssetCategory.find_by(name: 'Equipment')).pluck(:id).join(','))
    UserActivityLineItemFilter.find_by(name: 'Facilities').update!(fta_asset_classes: FtaAssetClass.where(fta_asset_category: FtaAssetCategory.find_by(name: 'Facilities')).pluck(:id).join(','))

    asset_klass = Rails.application.config.asset_base_class_name.constantize
    UserActivityLineItemFilter.find_by(name: 'Shared Ride Assets').update!(asset_query_string: asset_klass.joins("INNER JOIN assets_fta_mode_types ON #{asset_klass.table_name}.id = assets_fta_mode_types.#{asset_klass.to_s.foreign_key}").where('assets_fta_mode_types.fta_mode_type_id = ?', FtaModeType.find_by(name: 'Demand Response').id).to_sql)


    rail_car_ali_filter = UserActivityLineItemFilter.find_by(name: 'Rail and Locomotive')
    User.where(user_activity_line_item_filter_id: rail_car_ali_filter.id).update_all(user_activity_line_item_filter_id: UserActivityLineItemFilter.first.id)
    rail_car_ali_filter.destroy!
  end
end