class CreateUserActivityLineItemFilters < ActiveRecord::Migration
  def change
    create_table :user_activity_line_item_filters do |t|
      t.string :object_key,           :index => true, :limit => 12,  :null => false
      t.string :name,                 :limit => 64,  :null => false
      t.string :description,          :limit => 256,  :null => false
      t.integer :capital_project_type_id
      t.string :sogr_type
      t.integer :team_ali_code_id
      t.integer :asset_type_id
      t.integer :asset_subtype_id
      t.boolean :in_backlog
      t.references :resource,         :polymorphic => true
      t.integer :created_by_user_id,  :index => true
      t.boolean :active,              :null => false

      t.timestamps
    end

    create_table :user_activity_line_item_filters_organizations do |t|
      t.integer :user_activity_line_item_filter_id,     :index => true, :null => false
      t.integer :organization_id,                       :index => true, :null => false
    end

    create_table :users_user_activity_line_item_filters do |t|
      t.integer :user_id,                               :index => true, :null => false
      t.integer :user_activity_line_item_filter_id,     :index => true, :null => false
    end

    add_column :users, :user_activity_line_item_filter_id, :integer
  end
end
