class AddAssociationTransamAssetActivityLineItems < ActiveRecord::Migration[5.2]
  def change
    add_reference :activity_line_items_assets, :transam_asset, after: :asset_id
  end
end
