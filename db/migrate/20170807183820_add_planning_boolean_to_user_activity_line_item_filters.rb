class AddPlanningBooleanToUserActivityLineItemFilters < ActiveRecord::Migration[4.2]
  def change
    add_column :user_activity_line_item_filters, :planning_year, :string, after: :districts
  end
end
