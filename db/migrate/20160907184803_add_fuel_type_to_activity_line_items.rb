class AddFuelTypeToActivityLineItems < ActiveRecord::Migration
  def change
    add_reference :activity_line_items, :fuel_type, index: true
  end
end
