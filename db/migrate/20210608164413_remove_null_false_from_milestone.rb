class RemoveNullFalseFromMilestone < ActiveRecord::Migration[5.2]
  def change
  	change_column_null :milestones, :activity_line_item_id, true
  end
end
