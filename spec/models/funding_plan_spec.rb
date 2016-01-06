require 'rails_helper'

RSpec.describe FundingPlan, :type => :model do

  let(:test_plan) { create(:funding_plan) }

  describe 'associations' do
    it 'has an activity line item' do
      expect(test_plan).to belong_to(:activity_line_item)
    end
    it 'has a funding source' do
      expect(test_plan).to belong_to(:funding_source)
    end
  end
  describe 'validations' do
    it 'must have an activity line item' do
      test_plan.activity_line_item = nil
      expect(test_plan.valid?).to be false
    end
    it 'must have a funding source' do
      test_plan.funding_source = nil
      expect(test_plan.valid?).to be false
    end
    describe 'amount' do
      it 'must be a number' do
        test_plan.amount = 'abc'
        expect(test_plan.valid?).to be false
      end
      it 'cant be negative' do
        test_plan.amount = -10
        expect(test_plan.valid?).to be false
      end
    end
  end

  it '#allowable_params' do
    expect(FundingPlan.allowable_params).to eq([
      :activity_line_item_id,
      :funding_source_id,
      :amount
    ])
  end

  it '.to_s' do
    expect(test_plan.to_s).to eq(test_plan.name)
  end
  it '.name' do
    expect(test_plan.name).to eq("#{test_plan.funding_source.name} $#{test_plan.amount}")
  end

  it '.federal_share' do
    expect(test_plan.federal_share).to eq(50)
  end
  it '.state_share' do
    expect(test_plan.state_share).to eq(30)
  end
  it '.local_share' do
    expect(test_plan.local_share).to eq(20)
  end
  it '.federal_percentage' do
    expect(test_plan.federal_percentage).to eq(50)
  end
  it '.state_percentage' do
    expect(test_plan.state_percentage).to eq(30)
  end
  it '.local_percentage' do
    expect(test_plan.local_percentage).to eq(20)
  end

  it '.set_defaults' do
    expect(FundingPlan.new.amount).to eq(0)
  end
end
