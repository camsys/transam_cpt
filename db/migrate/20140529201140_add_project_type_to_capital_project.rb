class AddProjectTypeToCapitalProject < ActiveRecord::Migration
  def change
    add_column  :capital_projects, :capital_project_type_id,    :integer, :after => :team_category_id

    create_table :capital_project_types do |t|
      t.string  "name",              limit: 64,  null: false
      t.string  "display_icon_name", limit: 64,  null: false
      t.string  "description",       limit: 254, null: false
      t.boolean "active",                        null: false
    end

    add_index   :capital_projects, [:organization_id, :capital_project_type_id], :name => "capital_projects_idx4"
  end
end
