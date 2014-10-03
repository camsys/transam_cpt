class AlterCapitalProjectForStateMachine < ActiveRecord::Migration
  def change
    add_column    :capital_projects, :state, :string, :limit => 64, :after => :organization_id
    remove_column :capital_projects, :capital_project_status_type_id
    
    drop_table    :capital_project_status_types
    
    add_index     :capital_projects, [:organization_id, :state],  :name => :capital_projects_idx5

  end
end
