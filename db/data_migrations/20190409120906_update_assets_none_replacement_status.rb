class UpdateAssetsNoneReplacementStatus < ActiveRecord::DataMigration
  def up
    service = CapitalProjectBuilder.new

    TransamAsset.where(replacement_status_type_id: ReplacementStatusType.find_by(name: 'None').id).each do |asset|
      if asset.activity_line_items.count > 0
        service.update_asset_schedule(asset)
      end
    end


  end
end