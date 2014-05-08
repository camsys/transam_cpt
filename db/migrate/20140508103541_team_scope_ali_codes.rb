class TeamScopeAliCodes < ActiveRecord::Migration
  def change
    create_table :team_scope_ali_codes do |t|
      t.string  :name,        :limit => 64, :allow_nulls => false
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt
      t.string  :code,        :limit => 8,  :allow_nulls => false
      t.boolean :active  
    end
    add_index :team_scope_ali_codes, [:name], :name => "team_scope_ali_codes_idx1"
    add_index :team_scope_ali_codes, [:rgt],  :name => "team_scope_ali_codes_idx2"
    add_index :team_scope_ali_codes, [:code], :name => "team_scope_ali_codes_idx3"
    
    # Add teacm scope code to activity line items and capital projects tables
    add_column :activity_line_items,  :team_scope_ali_code_id, :integer,  :after => :capital_project_id
    add_column :capital_projects,     :team_scope_ali_code_id, :integer,  :after => :organization_id    
  end
end
