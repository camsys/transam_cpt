class AddDetailsToDraftProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :draft_projects, :title, :string
    add_column :draft_projects, :description, :string
    add_column :draft_projects, :justification, :string
  end
end
