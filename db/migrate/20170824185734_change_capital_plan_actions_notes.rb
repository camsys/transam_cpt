class ChangeCapitalPlanActionsNotes < ActiveRecord::Migration[4.2]
  def change
    change_column :capital_plan_actions, :notes, :text
    add_column :capital_plan_actions, :completed_pcnt, :integer, after: :notes
  end
end
