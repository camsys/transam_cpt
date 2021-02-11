class AddForeignKeysToDraftBudgetAllocation < ActiveRecord::Migration[5.2]
  def change
    add_reference :draft_budget_allocations, :draft_project_phase, foreign_key: true
    add_reference :draft_budget_allocations, :draft_budget, foreign_key: true
  end
end
