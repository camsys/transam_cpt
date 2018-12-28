require 'rails_helper'

RSpec.describe AliAssetMatcherService, :type => :service do

  let(:test_service) { AliAssetMatcherService.new }
  let(:test_ali) { create(:activity_line_item) }

  describe 'errors' do
    it 'no ali' do
      expect(test_service.match(nil)).to eq([])
    end
    it 'no capital project' do
      test_ali.capital_project = nil
      expect(test_service.match(test_ali)).to eq([])
    end
    it 'no org' do
      test_ali.capital_project.organization = nil

      expect(test_service.match(test_ali)).to eq([])
    end
  end

  describe 'ali codes' do
    it 'none' do
      test_policy = create(:policy, :organization => test_ali.capital_project.organization)
      test_rule = create(:policy_asset_subtype_rule, :policy => test_policy, :purchase_replacement_code => test_ali.team_ali_code.code)
      test_asset = create(:buslike_asset, :organization => test_ali.capital_project.organization, :asset_subtype => test_rule.asset_subtype)

      expect(test_service.match(test_ali)).to eq([])
    end
    it 'replacement' do
      test_policy = create(:policy, :organization => test_ali.capital_project.organization)
      test_rule = create(:policy_asset_subtype_rule, :policy => test_policy, :purchase_replacement_code => test_ali.team_ali_code.code)
      test_asset = create(:buslike_asset, :organization => test_ali.capital_project.organization, :asset_subtype => test_rule.asset_subtype, :scheduled_replacement_year => test_ali.capital_project.fy_year)

      expect(test_service.match(test_ali)).to include(test_asset)
    end
    it 'rehabilitation' do
      test_ali.team_ali_code = create(:rehabilitation_ali_code)
      test_policy = create(:policy, :organization => test_ali.capital_project.organization)
      test_rule = create(:policy_asset_subtype_rule, :policy => test_policy, :rehabilitation_code => test_ali.team_ali_code.code)
      test_asset = create(:buslike_asset, :organization => test_ali.capital_project.organization, :asset_subtype => test_rule.asset_subtype, :scheduled_rehabilitation_year => test_ali.capital_project.fy_year)

      expect(test_service.match(test_ali)).to include(test_asset)
    end
    it 'cannot include current assets of ALI' do
      skip 'Assumes transam_asset. Not yet testable.'
      test_ali.team_ali_code = create(:rehabilitation_ali_code)
      test_policy = create(:policy, :organization => test_ali.capital_project.organization)
      test_rule = create(:policy_asset_subtype_rule, :policy => test_policy, :rehabilitation_code => test_ali.team_ali_code.code)
      test_asset = create(:buslike_asset, :organization => test_ali.capital_project.organization, :asset_subtype => test_rule.asset_subtype, :scheduled_rehabilitation_year => test_ali.capital_project.fy_year)
      test_asset2 = create(:buslike_asset, :organization => test_ali.capital_project.organization, :asset_subtype => test_rule.asset_subtype, :scheduled_rehabilitation_year => test_ali.capital_project.fy_year)
      test_ali.assets << test_asset2
      test_ali.save!

      expect(test_service.match(test_ali)).to include(test_asset)
      expect(test_service.match(test_ali)).not_to include(test_asset2)
    end
  end




end
