require 'rails_helper'

RSpec.describe Milestone, :type => :model do

  let(:test_milestone) { create(:milestone) }

  describe 'associations' do
    it 'has an activity line item' do
      expect(test_milestone).to belong_to(:activity_line_item)
    end
    it 'has a type' do
      expect(test_milestone).to belong_to(:milestone_type)
    end
  end

  describe 'validations' do
    it 'must have an object key' do
      test_milestone.object_key = nil
      expect(test_milestone.valid?).to be false
    end
    it 'must have a type' do
      test_milestone.milestone_type = nil
      expect(test_milestone.valid?).to be false
    end
  end

  it '#allowable_params' do
    expect(Milestone.allowable_params).to eq([
      :id,
      :object_key,
      :milestone_type_id,
      :milestone_date,
      :comments
    ])
  end

end
