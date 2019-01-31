Rails.application.config.rails_admin_cpt_lookup_tables = ['CapitalProjectType', 'MilestoneType']

Rails.application.config.asset_auditor_config = {class_name: 'TransitAsset', query: {fta_asset_category: FtaAssetCategory.where.not(name: 'Infrastructure').ids, replacement_status_type_id: ReplacementStatusType.where.not(name: 'Underway').ids + [nil]}} if ActiveRecord::Base.connection.table_exists?(:fta_asset_categories)
