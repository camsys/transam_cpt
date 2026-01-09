class ChangeDraftProjectDescriptionAndJustificationToText < ActiveRecord::Migration[5.2]
  def change
    change_column :draft_projects, :description, :text
    change_column :draft_projects, :justification, :text
  end
end
