class AddAgencyBudgets < ActiveRecord::Migration
  def change
    # Budget Amounts for each agency
    create_table :budget_amounts do |t|
      t.string      :object_key,          :limit => 12, :null => :false
      t.references  :organization,                      :null => :false
      t.references  :funding_source,                    :null => :false   
      t.integer     :fy_year,                           :null => :false
      t.integer     :amount,                            :null => :false
      t.boolean     :estimated,                         :null => :false
      t.timestamps
    end
    
    add_index :budget_amounts, :object_key, :name => :budget_amounts_idx1
    add_index :budget_amounts, [:organization_id, :funding_source_id, :fy_year], :name => :budget_amounts_idx2
  end
end
