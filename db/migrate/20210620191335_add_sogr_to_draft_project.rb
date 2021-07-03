class AddSogrToDraftProject < ActiveRecord::Migration[5.2]
  def change
  	add_column :draft_projects, :sogr, :boolean, default: :false
  end
end
