class CleanupBadDataReplacementStatusUpdateEvents < ActiveRecord::DataMigration

  include FiscalYear

  def up
    ReplacementStatusUpdateEvent.where(replacement_status_type: ReplacementStatusType.find_by(name: 'Underway'), replacement_year: nil).each do |ae|
      ae.update!(replacement_year: fiscal_year_year_on_date(ae.updated_at))
      typed_asset = Asset.get_typed_asset(ae.asset)
      typed_asset.update_replacement_status
      typed_asset.update_sogr
    end
  end
end