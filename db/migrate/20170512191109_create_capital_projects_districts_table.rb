class CreateCapitalProjectsDistrictsTable < ActiveRecord::Migration
  def change
    create_table :capital_projects_districts do |t|
      t.integer   :capital_project_id, null: true
      t.integer   :district_id, null: true
    end

  end
end
