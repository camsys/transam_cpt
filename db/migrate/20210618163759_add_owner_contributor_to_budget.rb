class AddOwnerContributorToBudget < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_budgets, :owner_id, :integer 
  	add_column :draft_budgets, :contributor_id, :integer
  end
end
