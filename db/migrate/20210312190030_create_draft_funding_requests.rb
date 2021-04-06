class CreateDraftFundingRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :draft_funding_requests do |t|

      t.timestamps
    end
  end
end
