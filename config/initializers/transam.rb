Rails.application.config.rails_admin_cpt_lookup_tables = ['CapitalProjectType', 'MilestoneType']

begin
  Rails.application.config.asset_auditor_config = {class_name: 'TransitAsset', query: {fta_asset_category: FtaAssetCategory.where.not(name: 'Infrastructure').ids, replacement_status_type_id: ReplacementStatusType.ids + [nil]}}
rescue
  puts "skipped loading Rails.application.config that depends on DB"
end
