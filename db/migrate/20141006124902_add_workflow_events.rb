class AddWorkflowEvents < ActiveRecord::Migration
  def change
    create_table :workflow_events do |t|
      t.string    :object_key,      :limit => 12, :null => :false
      t.integer   :trackable_id,                  :null => :false
      t.string    :trackable_type,  :limit => 64, :null => :false
      t.string    :event_type,      :limit => 64, :null => :false
      t.integer   :created_by_id,                 :null => :false
      t.timestamps
    end
    
    add_index :workflow_events, :object_key,       :unique => :true,  :name => :workflow_events_idx1
    add_index :workflow_events, [:trackable_id, :trackable_type],     :name => :workflow_events_idx2
  end
end
