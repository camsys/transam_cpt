class AddReplacementStatusTypeTransamAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :transam_assets, :replacement_status_type_id, :integer, after: :in_backlog
  end
end
