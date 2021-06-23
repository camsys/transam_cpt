class AddCapitalProjectTypeToDraftProject < ActiveRecord::Migration[5.2]
  def change
  	add_reference :draft_projects, :capital_project_type, index: true
  end
end
