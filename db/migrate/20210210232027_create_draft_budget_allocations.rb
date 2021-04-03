class CreateDraftBudgetAllocations < ActiveRecord::Migration[5.2]
  def change
    create_table :draft_budget_allocations do |t|
      t.integer :amount
      t.string :object_key, limit: 12
      t.timestamps
    end
  end
end
