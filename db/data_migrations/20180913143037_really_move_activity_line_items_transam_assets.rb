class ReallyMoveActivityLineItemsTransamAssets < ActiveRecord::DataMigration
  def up
    ActivityLineItemsAsset.all.each do |ali_asset|
      ali_asset.update_columns(transam_asset_id: TransitAsset.find_by(asset_id: ali_asset.asset_id).try(:transam_asset).try(:id))
    end
  end
end