class AdjustProjectNumberColumnWidth < ActiveRecord::Migration
  def change
    # Increase the width of the project number coliumn for Capital Projects
    change_column :capital_projects, :project_number, :string, :limit => 32  
  end
end
