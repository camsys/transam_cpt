class AddVehicleDeliveryFlagToMilestones < ActiveRecord::Migration
  def change
    add_column  :milestone_types, :is_vehicle_delivery, :boolean, :after => :description
  end
end
