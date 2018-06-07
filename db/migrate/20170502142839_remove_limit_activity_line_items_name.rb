class RemoveLimitActivityLineItemsName < ActiveRecord::Migration[4.2]
  def change
    change_column :activity_line_items, :name, :string, :limit => nil
  end
end
