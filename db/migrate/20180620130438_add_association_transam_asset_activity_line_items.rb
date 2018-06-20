class AddAssociationTransamAssetActivityLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :activity_line_items_assets, :transam_asset_id, :integer, after: :asset_id
  end
end
