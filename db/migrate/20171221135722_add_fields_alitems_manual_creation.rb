class AddFieldsAlitemsManualCreation < ActiveRecord::Migration[4.2]
  def change
    add_column :activity_line_items, :purchased_new, :boolean, before: :active
    add_column :activity_line_items, :count, :integer, after: :purchased_new
    add_column :activity_line_items, :length, :integer, after: :count
  end
end