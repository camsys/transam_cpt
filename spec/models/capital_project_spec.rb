require 'rails_helper'

RSpec.describe CapitalProject, :type => :model do
  let(:test_project) { create(:capital_project) }
  let(:test_line_item) { create(:activity_line_item, :fy_year => Date.today.year) }

  describe 'associations' do
    it 'has an org' do
      expect(test_project).to belong_to(:organization)
    end
    it 'has an ali code' do
      expect(test_project).to belong_to(:team_ali_code)
    end
    it 'has a type' do
      expect(test_project).to belong_to(:capital_project_type)
    end
    it 'has activity line items' do
      expect(test_project).to have_many(:activity_line_items)
    end
    it 'has documents' do
      expect(test_project).to have_many(:documents)
    end
    it 'has comments' do
      expect(test_project).to have_many(:comments)
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
      :active,
      :district_ids=>[]
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

      test_project.multi_year = true
      test_project.activity_line_items << test_line_item
      test_project.save!

      expect(test_project.can_submit?).to be true
    end
  end

  describe 'finance' do
    before(:each) do
      test_project.activity_line_items << test_line_item
      test_project.save!
    end

    it '#total_cost' do 
      project_1 = create(:capital_project)
      project_2 = create(:capital_project)

      project_1.activity_line_items << create(:activity_line_item, anticipated_cost: 100)
      project_1.save!

      ali_with_estimated_cost = create(:activity_line_item, anticipated_cost: 0)
      project_2.activity_line_items << ali_with_estimated_cost
      project_2.save!
      # I have to explicitly set it after project save otherwise the estimated_cost will be overrided by ActivityLineItem#after_update_callback due to project change
      ali_with_estimated_cost.estimated_cost = 200 
      ali_with_estimated_cost.save!

      expect(CapitalProject.where(id: [project_1.id, project_2.id]).total_cost).to eq(300)
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
  end

  it '.fiscal_year' do
    expect(test_project.fiscal_year).to eq("#{test_project.fy_year-2000}-#{test_project.fy_year-2000+1}")
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
    expect(test_project.project_number).to eq("#{test_project.organization.short_name} 14-15 ##{test_project.id}")
  end

  it '.set_defaults' do
    new_project = CapitalProject.new

    expect(new_project.active).to be true
    expect(new_project.sogr).to be false
    expect(new_project.multi_year).to be false
    expect(new_project.emergency).to be false
    expect(new_project.state).to eq('unsubmitted')
    expect(new_project.project_number).to eq('TEMP')
    expect(new_project.fy_year).to eq(Date.today.month > 6 ? Date.today.year : Date.today.year - 1)
  end

  describe "callbacks" do
    let(:test_multi_year_project) {create(:capital_project, multi_year: true, fy_year: 2016)}
    let(:test_line_item) { create(:activity_line_item, :fy_year => 2018) }
    
    describe ".after_update_callback" do 
      it 'change multi_year to single year,all ALIs must be shifted to the Project FY' do 
        test_multi_year_project.activity_line_items << test_line_item
        test_multi_year_project.save!

        test_multi_year_project.update_attributes(multi_year: false)

        expect(test_line_item.reload.fy_year).to eq(2016)
      end

      it 'FY change, any ALI in a year PRIOR to the Project FY should be shifted to the new Project FY.' do 
        test_multi_year_project.activity_line_items << test_line_item
        test_multi_year_project.save!

        test_multi_year_project.update_attributes(fy_year: 2019)

        expect(test_line_item.reload.fy_year).to eq(2019)
      end
    end

  end
end
