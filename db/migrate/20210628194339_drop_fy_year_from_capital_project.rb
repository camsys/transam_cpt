class DropFyYearFromCapitalProject < ActiveRecord::Migration[5.2]
  def change
  	remove_column :draft_projects, :fy_year
  end
end
