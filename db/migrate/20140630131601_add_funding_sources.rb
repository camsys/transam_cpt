class AddFundingSources < ActiveRecord::Migration
  def change

    # Lookup Tables
    create_table :funding_source_types do |t|
      t.string    :name,                :limit => 64, :null => :false
      t.string    :description,                       :null => :false
      t.boolean   :active,                            :null => :false
    end

    # Funding Sources Table
    create_table :funding_sources do |t|
      t.string    :object_key,          :limit => 12, :null => :false
      t.string    :name,                :limit => 64, :null => :false
      t.text      :description,                       :null => :false
      t.integer   :funding_source_type_id,            :null => :false   
      t.string    :external_id,         :limit => 32
      
      t.boolean   :state_administered_federal_fund,   :null => :false
      t.boolean   :bond_fund,                         :null => :false
      t.boolean   :formula_fund,                      :null => :false
      t.boolean   :non_committed_fund,                :null => :false
      t.boolean   :contracted_fund,                   :null => :false
      t.boolean   :discretionary_fund,                :null => :false
      
      t.float     :state_match_requried,              :null => :true   
      t.float     :federal_match_requried,            :null => :true   
      t.float     :local_match_requried,              :null => :true   

      t.boolean   :rural_providers,                   :null => :true
      t.boolean   :urban_providers,                   :null => :true
      t.boolean   :shared_rider_providers,            :null => :true
      t.boolean   :inter_city_bus_providers,          :null => :true
      t.boolean   :inter_city_rail_providers,         :null => :true
      
      t.boolean   :active,                            :null => :false      
      t.timestamps
    end
    
    add_index :funding_sources, :object_key, :name => :funding_sources_idx1

    # Available Funds Table
    create_table :funding_amounts do |t|
      t.string    :object_key,          :limit => 12, :null => :false
      t.integer   :fy_year,                           :null => :false
      t.integer   :funding_source_id,                 :null => :false
      t.integer   :amount,                            :null => :false
      t.boolean   :estimated,                         :null => :false
      t.integer   :created_by_id,                     :null => :false
      t.integer   :updated_by_id,                     :null => :false
      t.boolean   :active,                            :null => :false      
      t.timestamps
    end

    add_index :funding_amounts, :object_key,                    :name => :funding_amounts_idx1
    add_index :funding_amounts, [:funding_source_id, :fy_year], :name => :funding_amounts_idx2

    # Funding Request  Table
    create_table :funding_requests do |t|
      t.string    :object_key,          :limit => 12, :null => :false
      t.integer   :activity_line_item_id,             :null => :false
      t.integer   :funding_source_id,                 :null => :false
      t.integer   :amount,                            :null => :false
      t.integer   :created_by,                        :null => :false
      t.integer   :updated_by,                        :null => :false
      t.timestamps
    end

    add_index :funding_requests, :object_key,                                   :name => :funding_requests_idx1
    add_index :funding_requests, [:activity_line_item_id, :funding_source_id],  :name => :available_funds_idx2

  end

end
