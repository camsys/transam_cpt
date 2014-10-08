class ModifyCapitalProjectWorkflowModel < ActiveRecord::Migration
  def change
    # Rename the auditing columns
    rename_column :workflow_events, :trackable_id,    :accountable_id
    rename_column :workflow_events, :trackable_type,  :accountable_type
  end
end
