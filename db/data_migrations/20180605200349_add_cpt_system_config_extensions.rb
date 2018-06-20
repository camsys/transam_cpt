class AddCptSystemConfigExtensions < ActiveRecord::DataMigration
  def up
    system_config_extensions = [
        {class_name: 'CapitalProject', extension_name: 'TransamKeywordSearchable', active: true},
        {class_name: 'ActivityLineItem', extension_name: 'TransamKeywordSearchable', active: true},

        {class_name: 'TransamAsset', extension_name: 'TransamAssetPlannable', active: true},

        {class_name: 'TransitOperator', extension_name: 'TransamPlanningOrganization', active: true},
        {class_name: 'Grantor', extension_name: 'TransamPlanningOrganization', active: true},
        {class_name: 'User', extension_name: 'TransamPlanningFilters', active: true}

    ]

    system_config_extensions.each do |extension|
      SystemConfigExtension.create!(extension)
    end
  end
end