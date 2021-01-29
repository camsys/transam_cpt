class AddNameToScenario < ActiveRecord::Migration[5.2]
  def change
    add_column :scenarios, :name, :string, null: :false 
    add_column :scenarios, :description, :text
  end
end
