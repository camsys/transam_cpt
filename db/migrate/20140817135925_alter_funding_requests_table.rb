class AlterFundingRequestsTable < ActiveRecord::Migration
  def change
    # Alter the funding_requests table to refer to funding_line_items instead of funding_amounts
    rename_column :funding_requests, :funding_amount_id, :funding_line_item_id
  end
end
