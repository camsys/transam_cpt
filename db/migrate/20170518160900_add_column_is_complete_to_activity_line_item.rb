class AddColumnIsCompleteToActivityLineItem < ActiveRecord::Migration
  def change
    unless column_exists? :activity_line_items, :is_planning_complete
      add_column :activity_line_items, :is_planning_complete, :boolean, before: :active
    end
  end
end
