class AddObjectKeyToDraftFundingSource < ActiveRecord::Migration[5.2]
  def change
    add_column :draft_funding_requests, :object_key, :string, limit: 12
  end
end
