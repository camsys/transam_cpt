class CleanUpCapitalProjects < ActiveRecord::Migration
  def change
    # Alter the ALI table
    #   Add costs columns
    add_column :activity_line_items, :anticipated_cost,   :integer, :after => :name
    add_column :activity_line_items, :estimated_cost,     :integer, :after => :anticipated_cost
    #   Remove unused columns
    remove_column :activity_line_items, :team_sub_category_id
    
    # Alter the capital projects table
    #   Remove unused columns
    remove_column :capital_projects, :team_scope_code_id
    remove_column :capital_projects, :team_category_id
    
    # Drop tables no longer needed
    drop_table :team_scope_categories
    drop_table :team_scope_codes
    drop_table :team_categories
    drop_table :team_sub_categories
    
  end
end
