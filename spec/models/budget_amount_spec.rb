require 'rails_helper'

RSpec.describe BudgetAmount, :type => :model do

  let(:test_amount) { create(:budget_amount) }

  describe 'associations' do
    it 'has an org' do
      expect(test_amount).to belong_to(:organization)
    end
    it 'has a funding source' do
      expect(test_amount).to belong_to(:funding_source)
    end
    it 'has many funding plans', :skip do
      expect(test_amount).to have_many(:funding_plans)
    end
  end

  describe 'validations' do
    it 'must have an object key' do
      test_amount.object_key = nil
      expect(test_amount.valid?).to be false
    end
    it 'must have an org' do
      test_amount.organization = nil
      expect(test_amount.valid?).to be false
    end
    it 'must have a funding source' do
      test_amount.funding_source = nil
      expect(test_amount.valid?).to be false
    end
    it 'must have a fiscal year' do
      test_amount.fy_year = nil
      expect(test_amount.valid?).to be false
    end
    it 'must have an amount' do
      test_amount.amount = nil
      expect(test_amount.valid?).to be false
    end
  end

  it '#allowable_params' do
    expect(BudgetAmount.allowable_params). to eq([
      :id,
      :object_key,
      :organization_id,
      :funding_source_id,
      :fy_year,
      :amount,
      :estimated
    ])
  end

  it '.name' do
    expect(test_amount.name).to eq(test_amount.funding_source.to_s)
  end
  it '.to_s' do
    expect(test_amount.to_s).to eq(test_amount.name)
    expect(test_amount.to_s).to eq(test_amount.funding_source.to_s)
  end
  it '.fiscal_year' do
    expect(test_amount.fiscal_year).to eq("FY #{test_amount.fy_year-2000}-#{test_amount.fy_year-2000+1}")
  end
  it '.spent', :skip do
    expect(test_amount.spent).to eq(test_amount.funding_plans.sum{|f| f.amount})
  end

  it '.set_defaults' do
    new_budget_amount = BudgetAmount.new
    expect(new_budget_amount.estimated).to be true
    expect(new_budget_amount.amount).to eq(0)
  end
end
