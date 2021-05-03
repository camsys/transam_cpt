class AddNotionalToDraftProject < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_projects, :notional, :boolean, default: false 
  end
end
