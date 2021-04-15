class AddSharedAcrossScenariosToDraftBudgets < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_budgets, :shared_across_scenarios, :boolean, default: false 
  end
end
