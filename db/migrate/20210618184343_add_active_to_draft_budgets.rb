class AddActiveToDraftBudgets < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_budgets, :active, :boolean, default: true 
  end
end
