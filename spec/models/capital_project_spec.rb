require 'rails_helper'

RSpec.describe CapitalProject, :type => :model do
  let(:test_project) { create(:capital_project) }
  let(:test_line_item) { create(:activity_line_item, :fy_year => Date.today.year) }

  describe 'associations' do
    it 'has an org' do
      expect(CapitalProject.column_names).to include('organization_id')
    end
    it 'has an ali code' do
      expect(CapitalProject.column_names).to include('team_ali_code_id')
    end
    it 'has a type' do
      expect(CapitalProject.column_names).to include('capital_project_type_id')
    end
    it 'has activity line items' do
      expect(ActivityLineItem.column_names).to include('capital_project_id')
    end
    it 'has documents' do

    end
    it 'has comments' do

    end
  end

  describe 'validations' do
    it 'must have an org' do
      test_project.organization = nil
      expect(test_project.valid?).to be false
    end
    it 'must have a team ali code' do
      test_project.team_ali_code = nil
      expect(test_project.valid?).to be false
    end
    it 'must have a type' do
      test_project.capital_project_type = nil
      expect(test_project.valid?).to be false
    end
    it 'must have a state' do
      test_project.state = nil
      expect(test_project.valid?).to be false
    end
    it 'must have a project_number' do
      test_project.project_number = nil
      expect(test_project.valid?).to be false
    end
    it 'must have a title' do
      test_project.title = nil
      expect(test_project.valid?).to be false
    end
    it 'must have a description' do
      test_project.description = nil
      expect(test_project.valid?).to be false
    end
    it 'must have a justification' do
      test_project.justification = nil
      expect(test_project.valid?).to be false
    end
    describe 'fy_year' do
      it 'must exist' do
        test_project.fy_year = nil
        expect(test_project.valid?).to be false
      end
      it 'must be a number' do
        test_project.fy_year = 'lksdjfh'
        expect(test_project.valid?).to be false
      end
      it 'must be after 1899' do
        test_project.fy_year = 1776
        expect(test_project.valid?).to be false
      end
    end
  end

  it '#allowable_params' do
    expect(CapitalProject.allowable_params).to eq([
      #:project_number,
      :organization_id,
      :fy_year,
      :team_ali_code_id,
      :capital_project_type_id,
      :state,
      :title,
      :description,
      :justification,
      :emergency,
      :multi_year,
      :active
    ])
  end

  describe '.can_update?' do
    it 'submitted' do
      test_project.update!(:state => 'approved')

      expect(test_project.can_update?).to be false
    end
    it 'not submitted' do
      expect(test_project.can_update?).to be true
    end
  end
  it '.sogr?' do
    expect(test_project.sogr?).to eq(test_project.sogr)
  end
  it '.multi_year?' do
    expect(test_project.multi_year?).to eq(test_project.multi_year)
  end
  it '.emergency?' do
    expect(test_project.emergency?).to eq(test_project.emergency)
  end
  describe'.can_submit?' do
    it 'total cost = 0' do
      expect(test_project.can_submit?).to be false
    end
    it 'total cost > 0' do
      test_line_item = create(:activity_line_item, :anticipated_cost => 123)
      test_line_item.funding_plans << create(:funding_plan, :amount => 100)
      test_line_item.save!

      test_project.multi_year = true
      test_project.activity_line_items << test_line_item
      test_project.save!

      expect(test_project.can_submit?).to be true
    end
  end

  describe 'finance' do
    before(:each) do
      test_line_item.funding_plans << create(:funding_plan)
      test_line_item.save!
      test_project.activity_line_items << test_line_item
      test_project.save!
    end

    it '.state_funds' do
      expect(test_project.state_funds).to eq(test_line_item.state_funds)
    end
    it '.federal_funds' do
      expect(test_project.federal_funds).to eq(test_line_item.federal_funds)
    end
    it '.local_funds' do
      expect(test_project.local_funds).to eq(test_line_item.local_funds)
    end
    it '.total_funds' do
      expect(test_project.total_funds).to eq(test_line_item.total_funds)
    end

    describe '.total_cost' do
      describe 'multi year' do
        before(:each) do
          test_project.update!(:multi_year => true)
        end
        it 'not selected fy' do
          expect(test_project.total_cost).to eq(test_line_item.cost)
        end
        it 'selected fy' do
          expect(test_project.total_cost Date.today.year).to eq(test_line_item.cost)
        end
      end
      describe 'not multi year' do
        it 'not selected fy' do
          expect(test_project.total_cost).to eq(0)
        end
        it 'selected fy' do
          expect(test_project.total_cost Date.today.year).to eq(test_line_item.cost)
        end
      end
    end

    it '.funding_difference' do
      expect(test_project.funding_difference).to eq(test_project.total_cost - test_project.total_funds)
    end
  end

  it '.fiscal_year' do
    expect(test_project.fiscal_year).to eq("FY #{test_project.fy_year-2000}-#{test_project.fy_year-2000+1}")
  end

  it '.to_s' do
    expect(test_project.to_s).to eq(test_project.project_number)
  end
  it '.name' do
    expect(test_project.name).to eq(test_project.project_number)
  end

  it '.searchable_fields' do
    expect(test_project.searchable_fields).to eq([
      :object_key,
      :project_number,
      :title,
      :description,
      :justification,
      :capital_project_type,
      :fy_year,
      :team_ali_code
    ])
  end

  it '.create_project_number' do
    expect(test_project.project_number).to eq("#{test_project.organization.short_name}-14-15-111-#{test_project.id}")
  end

  it '.set_defaults' do
    new_project = CapitalProject.new

    expect(new_project.active).to be true
    expect(new_project.sogr).to be false
    expect(new_project.multi_year).to be false
    expect(new_project.emergency).to be false
    expect(new_project.state).to eq('unsubmitted')
    expect(new_project.project_number).to eq('TEMP')
    expect(new_project.fy_year).to eq(Date.today.month > 6 ? Date.today.year : Date.today.year + 1)
  end
end
