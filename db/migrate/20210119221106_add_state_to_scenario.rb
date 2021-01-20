class AddStateToScenario < ActiveRecord::Migration[5.2]
  def change
    add_column :scenarios, :state, :string
  end
end
