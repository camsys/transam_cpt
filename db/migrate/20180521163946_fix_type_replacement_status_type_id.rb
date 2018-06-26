class FixTypeReplacementStatusTypeId < ActiveRecord::Migration[5.2]
  def change
    change_column :assets, :replacement_status_type_id, :integer
    change_column :asset_events, :replacement_status_type_id, :integer
  end
end
