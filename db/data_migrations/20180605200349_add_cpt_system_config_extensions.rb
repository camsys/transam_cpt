class AddCptSystemConfigExtensions < ActiveRecord::DataMigration
  def up
    system_config_extensions = [
        {class_name: 'CapitalProject', extension_name: 'TransamKeywordSearchable', active: true},
        {class_name: 'ActivityLineItem', extension_name: 'TransamKeywordSearchable', active: true},
        {class_name: 'RevenueVehicle', extension_name: 'TransamPlannable', active: true},
        {class_name: 'ServiceVehicle', extension_name: 'TransamPlannable', active: true},
        {class_name: 'CapitalEquipment', extension_name: 'TransamPlannable', active: true},
        {class_name: 'FacilityComponent', extension_name: 'TransamPlannable', active: true},
        {class_name: 'Facility', extension_name: 'TransamPlannable', active: true},
        {class_name: 'TransitOperator', extension_name: 'TransamPlanningOrganization', active: true},
        {class_name: 'Grantor', extension_name: 'TransamPlanningOrganization', active: true},
        {class_name: 'CapitalProject', extension_name: 'TransamFundableCapitalProject', active: true},
        {class_name: 'ActivityLineItem', extension_name: 'TransamFundable', active: true},
        {class_name: 'User', extension_name: 'TransamPlanningFilters', active: true}

    ]

    system_config_extensions.each do |extension|
      SystemConfigExetnsion.create!(extension)
    end
  end
end