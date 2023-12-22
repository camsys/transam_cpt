class AddPrimaryScenarioToScenarios < ActiveRecord::Migration[5.2]
  def change
    add_column :scenarios, :primary_scenario, :boolean
  end
end
