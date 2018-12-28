require 'rails_helper'

RSpec.describe ActivityLineItemsController, :type => :controller do

  let(:test_user)    { create(:normal_user) }
  let(:test_project) { create(:capital_project, :organization_id => test_user.organization_id) }
  let(:test_ali)      { create(:activity_line_item, :capital_project => test_project) }
  let(:test_asset)    { create(:buslike_asset) }

  before(:each) do
    sign_in test_user
  end

  it 'GET show' do
    Organization.get_typed_organization(test_ali.capital_project.organization).service_provider_types << ServiceProviderType.find_by_name('Urban')
    test_ali.capital_project.organization.save!
    test_policy = create(:policy, :organization => test_ali.capital_project.organization)
    test_rule = create(:policy_asset_subtype_rule, :policy => test_policy, :purchase_replacement_code => test_ali.team_ali_code.code)
    test_asset = create(:buslike_asset, :organization => test_ali.capital_project.organization, :asset_subtype => test_rule.asset_subtype, :scheduled_replacement_year => test_ali.capital_project.fy_year)
    get :show, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key}

    expect(assigns(:project)).to eq(test_project)
    expect(assigns(:activity_line_item)).to eq(test_ali)
    expect(assigns(:assets)).to include(test_asset)

  end

  it 'GET add_asset' do
    skip 'Assumes transam_asset. Not yet testable.'
    request.env["HTTP_REFERER"] = capital_project_activity_line_items_path(test_project)
    post :add_asset, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key, :asset => test_asset.object_key}

    expect(test_ali.assets).to include(test_asset)
  end
  it 'DELETE remove_asset' do
    skip 'Assumes transam_asset. Not yet testable.'

    request.env["HTTP_REFERER"] = capital_project_activity_line_items_path(test_project)
    test_ali.assets << test_asset
    test_ali.save!
    expect(test_ali.assets).to include(test_asset)

    post :remove_asset, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key, :asset => test_asset.object_key}
    test_ali.reload
    expect(test_ali.assets).not_to include(test_asset)
  end

  it 'GET new' do
    get :new, params:{:capital_project_id => test_project.object_key}

    expect(assigns(:project)).to eq(test_project)
    expect(assigns(:activity_line_item).to_json).to eq(ActivityLineItem.new.to_json)
  end
  it 'GET edit' do
    allow_any_instance_of(ActivityLineItemsController).to receive(:render).and_return ""
    get :edit, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key, format: :js}

    expect(assigns(:project)).to eq(test_project)
    expect(assigns(:activity_line_item)).to eq(test_ali)
  end
  it 'GET assets' do
    get :assets, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key, format: :json}

    expect(assigns(:project)).to eq(test_project)
    expect(assigns(:activity_line_item)).to eq(test_ali)
    expect(assigns(:fiscal_years)).to eq(test_ali.get_fiscal_years)
  end
  it 'GET edit_cost' do
    allow_any_instance_of(ActivityLineItemsController).to receive(:render).and_return ""
    get :edit_cost, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key, format: :js}

    expect(assigns(:project)).to eq(test_project)
    expect(assigns(:activity_line_item)).to eq(test_ali)
  end
  describe 'GET edit_milestones' do
    before(:each) do
      allow_any_instance_of(ActivityLineItemsController).to receive(:render).and_return ""
    end
    it 'vehicle delivery' do
      get :edit_milestones, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key, format: :js}

      expect(assigns(:project)).to eq(test_project)
      expect(assigns(:activity_line_item)).to eq(test_ali)
      expect(test_ali.milestones.count).to eq(MilestoneType.count)
    end
    it 'not vehicle delivery' do
      test_ali.update!(:team_ali_code => create(:rehabilitation_ali_code, :parent => create(:rehabilitation_ali_code)))
      get :edit_milestones, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key, format: :js}

      expect(assigns(:project)).to eq(test_project)
      expect(assigns(:activity_line_item)).to eq(test_ali)
      expect(test_ali.milestones.count).to eq(MilestoneType.where('is_vehicle_delivery = false').count)
    end
  end

  it 'POST create' do
    request.env["HTTP_REFERER"] = capital_project_activity_line_items_path(test_project)
    post :create, params:{:capital_project_id => test_project.object_key, :activity_line_item => attributes_for(:activity_line_item, :team_ali_code_id => create(:replacement_ali_code, :parent => create(:replacement_ali_code)).id)}
    test_project.reload

    expect(test_project.activity_line_items.count).to eq(1)
  end
  it 'POST update' do
    request.env["HTTP_REFERER"] = capital_project_activity_line_items_path(test_project)
    post :update, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key, :activity_line_item => {:name => 'activity line item name 222'}}
    test_ali.reload

    expect(test_ali.name).to eq('activity line item name 222')
  end
  it 'DELETE destroy' do
    request.env["HTTP_REFERER"] = capital_projects_path
    delete :destroy, params:{:capital_project_id => test_project.object_key, :id => test_ali.object_key}

    expect(assigns(:project)).to eq(test_project)
    expect(ActivityLineItem.find_by(:object_key => test_ali.object_key)).to be nil
  end
end
