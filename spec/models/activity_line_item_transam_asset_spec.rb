require 'rails_helper'

# Survivor-hierarchy mirrors (TTPLAT-3090) of the ActivityLineItem callback examples in
# spec/models/activity_line_item_spec.rb:167-218. The legacy examples build legacy Asset
# through :buslike_asset; these use TransamAsset (ActivityLineItem#assets is
# class_name: TransamAsset here).
#
# NOT mirrored, tripwire 2 (see ttplat-3090-cowork-report-cpt.md):
#   '.after_add_asset_callback' (legacy :167, :skip, no reason) and
#   '.after_remove_asset_callback' (legacy :176, skipped :177). The HABTM declaration
#     (activity_line_item.rb:49) has no :after_add / :after_remove options (they were
#     commented out before the 2018 hierarchy change), and nothing else calls the two
#     protected methods (activity_line_item.rb:309, :320), so assets <<, assets.delete and
#     assets.destroy never reach them. Wiring them is an app change.
RSpec.describe ActivityLineItem, :type => :model do

  let(:test_line_item) { create(:activity_line_item) }
  let(:test_org) { create(:organization) }
  let(:test_subtype) { AssetSubtype.first }

  # A TransamAsset needs a policy chain (PolicyAware#check_policy_rule), and its
  # scheduled_replacement_cost is derived from the policy on save, so it is pinned
  # afterwards with update_columns to a value the policy would never produce.
  let(:test_asset) do
    create(:parent_policy, :organization => test_org, :type => test_subtype.asset_type_id, :subtype => test_subtype.id, :has_fuel_type => false)
    asset = create(:transam_asset, :organization => test_org, :asset_subtype => test_subtype)
    asset.update_columns(:scheduled_replacement_cost => 123)
    asset
  end

  before(:each) do
    test_line_item.assets << test_asset
    # the add callback is not wired (see above), so the estimate has not moved
    expect(test_line_item.reload.estimated_cost).to eq(0)
    expect(test_line_item.total_asset_cost).to eq(123)
  end

  describe 'callbacks' do
    # Mirrors: activity_line_item_spec.rb:187-197 ('.after_update_callback capital_project updated';
    # skipped :188). NEW GROUND for the assertion: the legacy example asserts nothing (it only
    # stubs total_asset_cost and saves). Here the estimate is asserted: 0 before, the asset's
    # 123 after the capital project changes (ActivityLineItem#after_update_callback,
    # activity_line_item.rb:332).
    it '.after_update_callback capital_project updated' do
      test_line_item.capital_project = create(:capital_project, :fy_year => 2015)
      test_line_item.save!

      expect(test_line_item.reload.estimated_cost).to eq(123)
    end

    # Mirrors: activity_line_item_spec.rb:198-207 ('.after_update_callback fy_year updated';
    # skipped :199). Legacy asserted `expect(...).to receive(:total_asset_cost)`; kept, with
    # the resulting estimate added. Dropped from the legacy fixture:
    # estimated_replacement_cost (a calculator-derived value, not a column).
    it '.after_update_callback fy_year updated' do
      expect(test_line_item).to receive(:total_asset_cost).and_call_original
      test_line_item.fy_year = 2015
      test_line_item.save!

      expect(test_line_item.reload.estimated_cost).to eq(123)
    end

    # Mirrors: activity_line_item_spec.rb:208-217 ('.after_update_callback name updated';
    # skipped :209). Legacy asserted `expect(...).not_to receive(:total_asset_cost)`; kept,
    # with the unchanged estimate added.
    it '.after_update_callback name updated' do
      expect(test_line_item).not_to receive(:total_asset_cost)
      test_line_item.name = 'ALI 2'
      test_line_item.save!

      expect(test_line_item.reload.estimated_cost).to eq(0)
      expect(test_line_item.name).to eq('ALI 2')
    end
  end
end
