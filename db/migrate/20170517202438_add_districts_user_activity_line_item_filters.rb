class AddDistrictsUserActivityLineItemFilters < ActiveRecord::Migration
  def change
    add_column :user_activity_line_item_filters, :districts, :string, after: :team_ali_codes
  end
end
