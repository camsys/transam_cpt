class CreateDraftProjectDistricts < ActiveRecord::Migration[5.2]
  def change
    create_table :draft_project_districts do |t|

      t.integer :draft_project_id 
      t.integer :district_id
      t.string :object_key, limit: 12

      t.timestamps
    end
  end
end
