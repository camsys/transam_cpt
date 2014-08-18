class AddStateAndLocalFundsToFundingRequest < ActiveRecord::Migration
  def change
    # Alter the funding_requests table to refer to funding_line_items instead of funding_amounts
    rename_column :funding_requests, :funding_line_item_id, :federal_funding_line_item_id
    rename_column :funding_requests, :amount, :federal_amount

    add_column    :funding_requests, :state_funding_line_item_id, :integer, :after => :federal_funding_line_item_id
    add_column    :funding_requests, :state_amount, :integer, :after => :federal_amount
    add_column    :funding_requests, :local_amount, :integer, :after => :state_amount
    
  end
end
