require 'rails_helper'

RSpec.describe Milestone, :type => :model do

  let(:test_milestone) { create(:milestone) }

  describe 'associations' do
    it 'has an activity line item' do
      expect(Milestone.column_names).to include('activity_line_item_id')
    end
    it 'has a type' do
      expect(Milestone.column_names).to include('milestone_type_id')
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
    it 'must have a date' do
      test_milestone.milestone_date = nil
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
