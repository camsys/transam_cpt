class RemoveLimitActivityLineItemsName < ActiveRecord::Migration
  def change
    change_column :activity_line_items, :name, :string, :limit => nil
  end
end
