class AddAgencyFundingTables < ActiveRecord::Migration
  def change

    # Lookup tables
    create_table :funding_line_item_types do |t|
      t.string    :code,                :limit => 2,  :null => :false
      t.string    :name,                :limit => 64, :null => :false
      t.string    :description,                       :null => :false
      t.boolean   :active,                            :null => :false
    end
    
    # FundingLineItems Table
    create_table :funding_line_items do |t|
      t.string    :object_key,          :limit => 12, :null => :false
      t.integer   :organization_id,                   :null => :false        

      t.integer   :fy_year,                           :null => :false
      t.integer   :funding_source_id,                 :null => :false
      t.integer   :funding_line_item_type_id,         :null => :false
      t.string    :federal_project_number, :limit => 64, :null => :false
      t.boolean   :awarded,                           :null => :false
      t.integer   :amount,                            :null => :false

      t.integer   :pcnt_operating_assistance,         :null => :false
            
      t.integer   :created_by_id,                     :null => :false
      t.integer   :updated_by_id,                     :null => :false
      t.boolean   :active,                            :null => :false      
      t.timestamps
    end

    add_index :funding_line_items, [:object_key], :name => :funding_line_items_idx1
    add_index :funding_line_items, [:organization_id, :object_key], :name => :funding_line_items_idx2
    add_index :funding_line_items, [:federal_project_number], :name => :funding_line_items_idx3

  end
end
