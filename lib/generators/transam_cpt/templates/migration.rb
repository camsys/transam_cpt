class CreateTransamCptTables < ActiveRecord::Migration

  def self.up

    create_table :capital_project_types do |t|
      t.string  :name,        :limit => 32,   :null => false
      t.string  :code,        :limit => 4,    :null => false
      t.string  :description, :limit => 254,  :null => false
      t.boolean :active,                      :null => false
    end

    create_table :milestone_types do |t|
      t.string  :name,        :limit => 32,   :null => false
      t.boolean :is_vehicle_delivery,         :null => false
      t.string  :description, :limit => 254,  :null => false
      t.boolean :active,                      :null => false
    end

    create_table :activity_line_items do |t|
      t.string  :object_key,          :limit => 12,   :null => false
      t.integer :capital_project_id,                  :null => false
      t.integer :fy_year,                             :null => false
      t.integer :team_ali_code_id,                    :null => false
      t.string  :name,                :limit => 64,   :null => false
      t.integer :anticipated_cost,                    :null => false
      t.integer :estimated_cost,                      :null => false
      t.string  :cost_justification,  :limit => 1024
      t.boolean :active,                              :null => false
      t.timestamps
    end

    add_index     :activity_line_items, [:object_key],              :name => :activity_line_items_idx1
    add_index     :activity_line_items, [:capital_project_id],      :name => :activity_line_items_idx2

    create_table :activity_line_items_assets do |t|
      t.integer :activity_line_item_id,               :null => false
      t.integer :asset_id,                            :null => false
    end

    add_index     :activity_line_items_assets, [:activity_line_item_id, :asset_id], :name => :activity_line_items_assets_idx1

    create_table :capital_projects do |t|
      t.string  :object_key,          :limit => 12,   :null => false
      t.integer :organization_id,               :null => false
      t.integer :fy_year,                             :null => false
      t.integer :team_ali_code_id,                    :null => false
      t.integer :capital_project_type_id,             :null => false
      t.string  :project_number,      :limit => 32,   :null => false
      t.boolean :sogr,                                :null => false
      t.boolean :notional,                            :null => false
      t.boolean :multi_year,                          :null => false
      t.boolean :emergency,                           :null => false
      t.string  :state,               :limit => 32,   :null => false
      t.string  :title,               :limit => 64,   :null => false
      t.string  :description,         :limit => 254,  :null => false
      t.string  :justification,       :limit => 254,  :null => false
      t.boolean :active,                              :null => false
      t.timestamps
    end

    add_index     :capital_projects, [:object_key],               :name => :capital_projects_idx1
    add_index     :capital_projects, [:organization_id],          :name => :capital_projects_idx2
    add_index     :capital_projects, [:fy_year],                  :name => :capital_projects_idx3
    add_index     :capital_projects, [:capital_project_type_id],  :name => :capital_projects_idx4

    create_table :milestones do |t|
      t.string  :object_key,          :limit => 12,   :null => false
      t.integer :activity_line_item_id,               :null => false
      t.integer :milestone_type_id,                   :null => false
      t.date    :milestone_date,                      :null => false
      t.string  :comments,            :limit => 254,  :null => false
      t.integer :created_by_id,                       :null => false
      t.timestamps
    end

    add_index     :milestones, [:object_key],             :name => :milestones_idx1
    add_index     :milestones, [:activity_line_item_id],  :name => :milestones_idx2
    add_index     :milestones, [:milestone_type_id],      :name => :milestones_idx3

  end

  def self.down
    drop_table :activity_line_items
    drop_table :activity_line_items_assets
    drop_table :capital_project_types
    drop_table :capital_projects
    drop_table :milestone_types
    drop_table :milestones
  end

end
