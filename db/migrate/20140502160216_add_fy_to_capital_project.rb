class AddFyToCapitalProject < ActiveRecord::Migration
  def change
    add_column  :capital_projects, :fy_year,              :integer, :after => :object_key

    add_index   :capital_projects, [:organization_id, :fy_year], :name => "capital_projects_idx3"

  end
end
