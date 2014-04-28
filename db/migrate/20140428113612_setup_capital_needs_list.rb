class SetupCapitalNeedsList < ActiveRecord::Migration
  def change

    # Lookup Tables
    create_table :capital_project_status_types do |t|
      t.string    :name,                :limit => 64, :null => :false
      t.string    :description,                       :null => :false
      t.boolean   :active,                            :null => :false
    end

    create_table :milestone_types do |t|
      t.string    :name,                :limit => 64, :null => :false
      t.string    :description,                       :null => :false
      t.boolean   :active,                            :null => :false
    end

    # TEAM Tables    
    create_table :team_scope_categories do |t|
      t.string    :name,                              :null => :false
      t.boolean   :active,                            :null => :false
    end 

    create_table :team_scope_codes do |t|
      t.integer   :team_scope_category_id,            :null => :false
      t.string    :code,                :limit => 6,  :null => :false
      t.string    :name,                              :null => :false
      t.string    :instructions,                      :null => :false
      t.boolean   :active,                            :null => :false
    end 
    add_index :team_scope_codes, [:team_scope_category_id, :code], :name => "team_scope_codes_idx1"
    
    create_table :team_categories do |t|
      t.integer   :team_scope_code_id,                :null => :false
      t.string    :code,                :limit => 2,  :null => :false
      t.string    :name,                              :null => :false
      t.boolean   :active,                            :null => :false
    end
    add_index :team_categories, [:team_scope_code_id, :code], :name => "team_categories_idx1"

    create_table :team_sub_categories do |t|
      t.integer   :team_category_id,                  :null => :false
      t.string    :code,                :limit => 2,  :null => :false
      t.string    :name,                              :null => :false
      t.boolean   :active,                            :null => :false
    end
    add_index :team_sub_categories, [:team_category_id, :code], :name => "team_sub_categories_idx1"
    
    # Capital Needs List Models
    create_table :capital_projects do |t|
      t.string    :object_key,          :limit => 12, :null => :false
      t.string    :project_number,      :limit => 16, :null => :false
      t.integer   :organization_id,                   :null => :false   
      t.integer   :team_scope_code_id,                :null => :false   
      t.integer   :team_category_id,                  :null => :false   
      t.integer   :capital_project_status_type_id,    :null => :false   
      t.string    :title,               :limit => 80, :null => :false
      t.text      :description,                       :null => :false
      t.boolean   :emergency,                         :null => :false
      t.boolean   :active,                            :null => :false
      
      t.timestamps
    end
    
    add_index :capital_projects, [:organization_id, :object_key], :name => "capital_projects_idx1"
    add_index :capital_projects, [:organization_id, :project_number], :name => "capital_projects_idx2"

    create_table :activity_line_items do |t|
      t.string    :object_key,          :limit => 12, :null => :false
      t.integer   :capital_project_id,                :null => :false   
      t.integer   :team_sub_category_id,              :null => :false   
      t.string    :name,                :limit => 80, :null => :false
      t.boolean   :active,                            :null => :false
      
      t.timestamps
    end
    add_index :activity_line_items, [:capital_project_id, :object_key], :name => "activity_line_items_idx1"
    
    create_table :mpms_projects do |t|
      t.integer   :capital_project_id,                :null => :false   
      t.integer   :external_id,         :limit => 32, :null => :false   
      t.string    :name,                :limit => 64, :null => :false
      t.string    :description,                       :null => :false
      t.boolean   :active,                            :null => :false
    end
    add_index :mpms_projects, [:capital_project_id], :name => "mpms_projects_idx1"
    
    create_table :milestones do |t|
      t.string    :object_key,          :limit => 12, :null => :false
      t.integer   :activity_line_item_id,             :null => :false   
      t.integer   :milestone_type_id,                 :null => :false   
      t.date      :milestone_date,                    :null => :false
      t.string    :comments,                          :null => :false
      t.integer   :created_by_id,                     :null => :false   

      t.timestamps
    end
    add_index :milestones, [:activity_line_item_id, :object_key],     :name => "milestones_idx1"
    add_index :milestones, [:activity_line_item_id, :milestone_date], :name => "milestones_idx2"
    
  end
end
