class ChangeUserActivityLineItemFilters < ActiveRecord::Migration[4.2]
  def change
    rename_column :user_activity_line_item_filters, :team_ali_code_id, :team_ali_codes
    change_column :user_activity_line_item_filters, :team_ali_codes, :string

    rename_column :user_activity_line_item_filters, :asset_type_id, :asset_types
    change_column :user_activity_line_item_filters, :asset_types, :string

    rename_column :user_activity_line_item_filters, :asset_subtype_id, :asset_subtypes
    change_column :user_activity_line_item_filters, :asset_subtypes, :string

    add_column :user_activity_line_item_filters, :asset_query_string, :string, after: :asset_subtypes
  end
end
