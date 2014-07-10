class FixFundingSourcesTable < ActiveRecord::Migration
  def change
    # Fix the column names in the funding_sources table
    rename_column :funding_sources, :state_match_requried, :state_match_required
    rename_column :funding_sources, :federal_match_requried, :federal_match_required
    rename_column :funding_sources, :local_match_requried, :local_match_required
  end
end
