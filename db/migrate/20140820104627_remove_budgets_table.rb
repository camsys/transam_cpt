class RemoveBudgetsTable < ActiveRecord::Migration
  def change
    
    # Drop tables no longer needed
    drop_table :budgets
    
  end
end
