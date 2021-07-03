class AddDefaultToBudget < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_budgets, :default, :boolean, default: :false 
  end
end
