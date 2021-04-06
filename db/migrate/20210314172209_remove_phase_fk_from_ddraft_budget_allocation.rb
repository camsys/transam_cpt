class RemovePhaseFkFromDdraftBudgetAllocation < ActiveRecord::Migration[5.2]
  def change
    remove_reference :draft_budget_allocations, :draft_project_phase, index: true, foreign_key: true
  end
end
