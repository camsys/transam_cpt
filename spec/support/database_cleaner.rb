RSpec.configure do |config|

  DatabaseCleaner.strategy = :truncation, {:only => %w[activity_line_items activity_line_items_assets assets asset_events capital_projects funding_sources milestones organizations policies policy_asset_subtype_rules policy_asset_type_rules team_ali_codes users transam_assets workflow_events]}
  config.before(:suite) do
    begin
      DatabaseCleaner.start
    ensure
      DatabaseCleaner.clean
    end
  end
end
