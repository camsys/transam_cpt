class FixFundingRequestsTable < ActiveRecord::Migration
  def change
    # Fix the column names in the funding_sources table
    rename_column :funding_requests, :funding_source_id, :funding_amount_id
    rename_column :funding_requests, :created_by, :created_by_id
    rename_column :funding_requests, :updated_by, :updated_by_id
  end
end
