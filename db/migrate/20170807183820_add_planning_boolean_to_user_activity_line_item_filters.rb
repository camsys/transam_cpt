class AddPlanningBooleanToUserActivityLineItemFilters < ActiveRecord::Migration
  def change
    add_column :planning_year, :user_activity_line_item_filters, :string, after: :districts
  end
end
