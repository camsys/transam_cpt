class AddScenarioToDraftProject < ActiveRecord::Migration[5.2]
  def change
    add_reference :draft_projects, :scenario, foreign_key: true
  end
end
