class CreateCapitalProjectsDistrictsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :capital_projects_districts do |t|
      t.integer   :capital_project_id, null: true
      t.integer   :district_id, null: true
    end

  end
end
