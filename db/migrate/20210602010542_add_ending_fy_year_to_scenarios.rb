class AddEndingFyYearToScenarios < ActiveRecord::Migration[5.2]
  def change
  	add_column :scenarios, :ending_fy_year, :integer
  end
end
