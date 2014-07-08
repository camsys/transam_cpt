class AddAgencyBudget < ActiveRecord::Migration
  def change
    # Budgets
    create_table :budgets do |t|
      t.string    :object_key,          :limit => 12, :null => :false
      t.integer   :fy_year,                           :null => :false
      t.integer   :organization_id,                   :null => :false
      t.integer   :funding_source_type_id,            :null => :false   
      t.integer   :amount,                            :null => :false
      t.boolean   :estimated,                         :null => :false
      t.timestamps
    end
    
    add_index :budgets, :object_key, :name => :budgets_idx1
    add_index :budgets, [:organization_id, :fy_year, :funding_source_type_id], :name => :budgets_idx2
    
  end
end
