class MoveActivityLineItemsTransamAssets < ActiveRecord::DataMigration
  def up
    ActivityLineItemsAsset.where(transam_asset_id: nil).where.not(asset_id: nil).each do |ali_asset|
      ali_asset.update_columns(transam_asset_id: TransitAsset.find_by(asset_id: ali_asset.asset_id).transam_asset.id)
    end
  end
end