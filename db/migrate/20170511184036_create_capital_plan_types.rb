class CreateCapitalPlanTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :capital_plan_types do |t|
      t.string :name
      t.string :description
      t.boolean :active
    end

    add_column :organizations, :capital_plan_type_id, :integer
  end
end
