class AddFundingSourceRelationships < ActiveRecord::Migration[5.2]
  def change
    add_reference :draft_funding_requests, :draft_project_phase, foreign_key: true, on_delete: :cascade
    add_reference :draft_budget_allocations, :draft_funding_request, foreign_key: true, on_delete: :cascade
  end
end
