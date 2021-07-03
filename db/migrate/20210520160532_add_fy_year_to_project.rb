class AddFyYearToProject < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_projects, :fy_year, :integer 
  end
end
