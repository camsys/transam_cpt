class CreateDraftBudgets < ActiveRecord::Migration[5.2]
  def change
    create_table :draft_budgets do |t|
      t.string :name
      t.integer :amount
      t.string :object_key, limit: 12
      t.timestamps
    end
  end
end
