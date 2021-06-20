class AddEmergencyToDraftProject < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_projects, :emergency, :boolean, default: :false
  end
end
