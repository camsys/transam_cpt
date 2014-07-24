class RenameFundingSourceColumn < ActiveRecord::Migration
  def change
    rename_column :funding_sources, :shared_rider_providers, :shared_ride_providers
  end
end
