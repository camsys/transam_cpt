class CreateDraftProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :draft_projects do |t|
      t.string :object_key, limit: 12
      t.string :project_number
      
      t.timestamps
    end
  end
end
