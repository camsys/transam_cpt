class MakeActivityLineItemAssetsNullable < ActiveRecord::Migration[5.2]
  def change
    change_column :activity_line_items_assets, :asset_id, :integer, null: true
  end
end
