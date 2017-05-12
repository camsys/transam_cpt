class CreateCapitalPlanTypes < ActiveRecord::Migration
  def change
    create_table :capital_plan_types do |t|
      t.string :name
      t.string :description
      t.boolean :active
    end

    capital_plan_types = [
        {name: 'Transit Capital Plan', description: 'Transit Capital Plan', active: true}
    ]

    capital_plan_types.each do |type|
      CapitalPlanType.create!(type)
    end
  end
end
