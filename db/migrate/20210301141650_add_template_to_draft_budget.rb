class AddTemplateToDraftBudget < ActiveRecord::Migration[5.2]
  def change
    add_reference :draft_budgets, :funding_template, foreign_key: true
  end
end
