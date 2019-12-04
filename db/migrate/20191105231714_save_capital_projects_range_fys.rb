class SaveCapitalProjectsRangeFys < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :capital_projects_range_fys, :integer
  end
end
