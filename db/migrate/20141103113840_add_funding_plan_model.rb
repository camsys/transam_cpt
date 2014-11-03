class AddFundingPlanModel < ActiveRecord::Migration
  def change
    # Funding Plan
    create_table :funding_plans do |t|
      t.string      :object_key,          :limit => 12, :null => :false
      t.references  :activity_line_item,                :null => :false
      t.references  :budget_amount,                     :null => :false   
      t.integer     :amount,                            :null => :false
      t.timestamps
    end
    
    add_index :funding_plans, :object_key,            :name => :funding_plans_idx1
    add_index :funding_plans, :activity_line_item_id, :name => :funding_plans_idx2
    add_index :funding_plans, :budget_amount_id,      :name => :funding_plans_idx3
  end
end
