require 'rails_helper'

RSpec.describe ActivityLineItem, :type => :model do

  let(:test_line_item) { create(:activity_line_item) }

  describe 'associations' do
    it 'belongs to capital project' do
      expect(test_line_item).to belong_to(:capital_project)
    end
    it 'has a team ali code' do
      expect(test_line_item).to belong_to(:team_ali_code)
    end
    it 'has many milestones' do
      expect(test_line_item).to have_many(:milestones)
    end
  end
  describe 'validations' do
    it 'must have a capital project' do
      test_line_item.capital_project = nil
      expect(test_line_item.valid?).to be false
    end
    it 'must have a name' do
      test_line_item.name = nil
      expect(test_line_item.valid?).to be false
    end
    describe 'anticipated cost' do
      it 'must exist' do
        test_line_item.anticipated_cost = nil
        expect(test_line_item.valid?).to be false
      end
      it 'must be a number' do
        test_line_item.anticipated_cost = 'abc'
        expect(test_line_item.valid?).to be false
      end
      it 'cant be negative' do
        test_line_item.anticipated_cost = -10
        expect(test_line_item.valid?).to be false
      end
    end
    it 'must have an ali code' do
      test_line_item.team_ali_code = nil
      expect(test_line_item.valid?).to be false
    end
    describe 'fiscal year' do
      it 'must exist' do
        test_line_item.fy_year = nil
        expect(test_line_item.valid?).to be false
      end
      it 'must be a number' do
        test_line_item.fy_year = 'abc'
        expect(test_line_item.valid?).to be false
      end
      it 'must be after 1899' do
        test_line_item.fy_year = 1776
        expect(test_line_item.valid?).to be false
      end
    end
  end

  it '#allowable_params' do
    expect(ActivityLineItem.allowable_params).to eq([
      :capital_project_id,
      :fy_year,
      :name,
      :team_ali_code_id,
      :anticipated_cost,
      :count,
      :purchased_new,
      :length,
      :fuel_type_id,
      :cost,
      :cost_justification,
      :active,
      :asset_ids => [],
      :milestones_attributes => [Milestone.allowable_params]
    ])
  end


  it '.to_s' do
    expect(test_line_item.to_s).to eq(test_line_item.name)
  end

  describe 'finance' do

    it '.cost_difference' do
      test_line_item.update!(:anticipated_cost => 456, :estimated_cost => 123)

      expect(test_line_item.cost_difference).to eq(333)
    end
    describe '.cost' do
      it 'is anticipated' do
        test_line_item.anticipated_cost = 123
        expect(test_line_item.cost).to eq(123)
      end
      it 'is not anticipated' do
        expect(test_line_item.estimated_cost).to eq(0)
        expect(test_line_item.cost).to eq(test_line_item.total_asset_cost)
        expect(test_line_item.estimated_cost).to eq(test_line_item.total_asset_cost)
      end
    end
    it '.restore_estimated_cost' do 
      test_line_item.anticipated_cost = 123
      test_line_item.estimated_cost = 100
      test_line_item.restore_estimated_cost

      expect(test_line_item.anticipated_cost).to eq(0)
      expect(test_line_item.estimated_cost).to eq(100)
    end

    describe '.total_asset_cost', :skip do
      before(:each) do

      end
      it 'assets have scheduled rehabilitation cost' do
        test_asset = create(:buslike_asset, :scheduled_rehabilitation_cost => 123)
        test_policy = create(:policy, :organization => test_asset.organization)
        create(:policy_asset_type_rule, :policy => test_policy, :asset_type => test_asset.asset_type)
        create(:policy_asset_subtype_rule, :policy => test_policy, :asset_subtype => test_asset.asset_subtype)

        test_line_item.assets << test_asset
        test_line_item.save!

        expect(test_line_item.total_asset_cost).to eq(123)
      end
      it 'policy' do
        test_asset = create(:buslike_asset)
        test_policy = create(:policy, :organization => test_asset.organization)
        create(:policy_asset_type_rule, :policy => test_policy, :asset_type => test_asset.asset_type)
        create(:policy_asset_subtype_rule, :policy => test_policy, :asset_subtype => test_asset.asset_subtype, :rehabilitation_labor_cost => 123, :rehabilitation_parts_cost => 456)

        test_line_item.assets << test_asset
        test_line_item.save!

        expect(test_line_item.total_asset_cost).to eq(579)
      end
      it 'calculate' do
        pending('TODO')
      end
    end
  end

  describe '.rehabilitation_ali?' do
    it 'no rehabilitation' do
      expect(test_line_item.rehabilitation_ali?).to be false
    end
    it 'team ali rehabilitation' do
      test_line_item.team_ali_code.update!(:code => '11.14.XX')

      expect(test_line_item.rehabilitation_ali?).to be true
    end
  end
  it '.organization' do
    expect(test_line_item.organization).to eq(test_line_item.capital_project.organization)
  end
  it '.update_estimated_cost' do
    test_line_item.update_estimated_cost
    expect(test_line_item.estimated_cost).to eq(test_line_item.total_asset_cost)
  end

  it '.searchable_fields' do
    expect(test_line_item.searchable_fields).to eq([:object_key, :name, :team_ali_code])
  end

  describe 'callbacks' do
    it '.after_add_asset_callback', :skip do
      expect(test_line_item.estimated_cost).to eq(0)
      test_asset = create(:buslike_asset, :scheduled_replacement_cost => 123,
                          :asset_type => AssetType.first, :asset_subtype => AssetSubtype.first)
      test_line_item.assets << test_asset
      test_line_item.save!

      expect(test_line_item.estimated_cost).to eq(123)
    end
    it '.after_remove_asset_callback', :skip do
      test_asset = create(:buslike_asset, :scheduled_replacement_cost => 123)
      test_line_item.assets << test_asset
      test_line_item.save!
      expect(test_line_item.estimated_cost).to eq(123)

      test_line_item.assets.delete(test_asset)
      test_line_item.reload
      expect(test_line_item.estimated_cost).to eq(0)
    end
    it '.after_update_callback capital_project updated' do
      test_asset = create(:buslike_asset, :estimated_replacement_cost => 123)
      test_line_item.assets << test_asset
                          
      # Fake a re-estimation based on changed capital project
      # by updating asset and then changing project
      expect(test_line_item).to receive(:total_asset_cost)
      test_cp = create(:capital_project, fy_year: 2015)
      test_line_item.capital_project = test_cp
      test_line_item.save!
    end
    it '.after_update_callback fy_year updated' do
      test_asset = create(:buslike_asset, :estimated_replacement_cost => 123)
      test_line_item.assets << test_asset
      # Fake a re-estimation based on changed capital project
      # by updating asset and then changing project
      expect(test_line_item).to receive(:total_asset_cost)
      test_line_item.fy_year = 2015
      test_line_item.save!
    end
    it '.after_update_callback name updated' do
      # Changing another field should not force a re-estimation
      test_asset = create(:buslike_asset, :estimated_replacement_cost => 123)
      test_line_item.assets << test_asset
      # Fake a re-estimation based on changed capital project
      # by updating asset and then changing project
      expect(test_line_item).not_to receive(:total_asset_cost)
      test_line_item.name = 'ALI 2'
      test_line_item.save!
    end
  end


  describe '.set_defaults' do
    let (:new_line_item) { ActivityLineItem.new }

    it 'defaults' do
      expect(new_line_item.active).to be true
      expect(new_line_item.estimated_cost).to eq(0)
      expect(new_line_item.anticipated_cost).to eq(0)
    end
    describe 'category_team_ali_code' do
      it 'no team ali code' do
        expect(new_line_item.category_team_ali_code).to eq('')
      end
      it 'has ali code' do
        ali_code =  create(:team_ali_code, :parent => create(:team_ali_code))
        expect(ActivityLineItem.new(:team_ali_code => ali_code).category_team_ali_code).to eq(ali_code.parent.code)
      end
    end
  end
end
