class AddRequiredToMilestone < ActiveRecord::Migration[5.2]
  def change
  	add_column :milestone_types, :required, :boolean, default: false 
  end
end
