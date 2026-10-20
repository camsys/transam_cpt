require 'rails_helper'

# Survivor-hierarchy mirrors (TTPLAT-3090) of spec/jobs/asset_disposition_update_job_spec.rb
# (both examples skipped by a `before` at :8, 'Assumes transam_asset', so neither ran).
# The AssetDispositionUpdateJob that loads is cpt's: execute_job and prepare resolve to
# transam_cpt/app/jobs/asset_disposition_update_job.rb; #run is inherited from core's
# AbstractAssetUpdateJob.
RSpec.describe AssetDispositionUpdateJob, :type => :job do

  let(:test_org) { create(:organization) }
  let(:test_subtype) { AssetSubtype.first }
  let(:test_asset) do
    create(:parent_policy, :organization => test_org, :type => test_subtype.asset_type_id, :subtype => test_subtype.id, :has_fuel_type => false)
    create(:transam_asset, :organization => test_org, :asset_subtype => test_subtype)
  end
  let(:test_line_item) { create(:activity_line_item) }

  # Mirrors: asset_disposition_update_job_spec.rb:10-23 ('.run').
  # Changed: the legacy disposition_type assertion is dropped: the survivor has no
  # disposition_type (TransamAsset does not respond to it); recorded as a gap, not added.
  # The legacy example never linked the asset to the line item, so its ALI assertions
  # held trivially; here the asset is linked first and removal is asserted.
  # Not asserted: estimated_cost. The remove callback is not wired (see
  # activity_line_item_transam_asset_spec.rb), so removal does not change it.
  it '#run' do
    test_line_item.assets << test_asset
    expect(test_line_item.reload.assets).to eq([test_asset])
    expect(test_asset.disposition_date).to be_nil
    test_asset.disposition_updates.create!(attributes_for(:disposition_update_event))

    AssetDispositionUpdateJob.new(test_asset.object_key).run
    test_asset.reload

    # check ali updates
    expect(test_line_item.reload.assets).to eq([])

    # check disposition updates
    expect(test_asset.disposition_date).to eq(Date.today)
    expect(test_asset.service_status_type).to eq(ServiceStatusType.find_by(:code => 'D'))
    expect(test_asset).not_to respond_to(:disposition_type)
  end

  # Mirrors: asset_disposition_update_job_spec.rb:25-34 ('.prepare'). Same assertion: the
  # job logs 'Executing AssetDispositionUpdateJob at <time> for Asset <object_key>'.
  # Changed: allow(Rails.logger).to receive(:debug) added so other debug calls do not fail it.
  it '#prepare' do
    test_asset.save!
    test_line_item.save!
    test_line_item.assets << test_asset

    allow(Time).to receive(:now).and_return(Time.utc(2000, "jan", 1, 20, 15, 1))
    allow(Rails.logger).to receive(:debug)
    expect(Rails.logger).to receive(:debug).with("Executing AssetDispositionUpdateJob at #{Time.now.to_s} for Asset #{test_asset.object_key}")

    AssetDispositionUpdateJob.new(test_asset.object_key).prepare
  end
end
