class AddFtaAssetClassesUserActivityLineItemFilters < ActiveRecord::Migration[5.2]
  def change
    add_column :user_activity_line_item_filters, :fta_asset_classes, :string, after: :asset_types
  end
end
