require 'rails_helper'
include FiscalYear

RSpec.describe CapitalProjectsController, :type => :controller do

  let(:test_user)    { create(:normal_user) }
  let(:test_project) { create(:capital_project, :organization_id => test_user.organization_id) }

  before(:each) do
    sign_in test_user
  end

  it 'GET fire_workflow_event' do
    request.env["HTTP_REFERER"] = capital_projects_path
    get :fire_workflow_event, params:{:id => test_project.object_key, :event => 'submit'}
    test_project.reload

    expect(test_project.state).to eq('pending_review')

  end
  it 'GET load_view' do
    allow_any_instance_of(CapitalProjectsController).to receive(:render).and_return ""
    get :load_view, params:{:id => test_project.object_key, format: :js}

    expect(assigns(:project)).to eq(test_project)
  end

  it 'GET builder' do
    test_asset_type = create(:asset_type)
    test_parent_policy = create(:parent_policy, type: test_asset_type.id, subtype: create(:asset_subtype, asset_type: test_asset_type).id)
    test_policy = create(:policy, organization: test_project.organization, parent: test_parent_policy)
    test_asset = create(:transam_asset,
                        :organization => test_policy.organization,
                        :asset_subtype => test_parent_policy.policy_asset_subtype_rules.first.asset_subtype,
                        :scheduled_replacement_year => test_project.fy_year)
    get :builder

    expected_first_year = Date.today.month < 7 ? Date.today.year : Date.today.year + 1
    expected_last_year = (expected_first_year - 1) + SystemConfig.instance.num_forecasting_years
    expect(assigns(:fiscal_years)).to start_with([fiscal_year(expected_first_year), expected_first_year]).and end_with([fiscal_year(expected_last_year), expected_last_year])
  end

  it 'POST runner' do
    pending('TODO')
    fail
    post :runner
  end

  describe 'GET index' do
    expected_first_year = Date.today.month < 7 ? Date.today.year : Date.today.year + 1
    expected_last_year = (expected_first_year - 1) + SystemConfig.instance.num_forecasting_years
    it 'nil fy_year config (automatic rollover)' do
      get :index
      expect(assigns(:first_year)).to eq(expected_first_year)
      expect(assigns(:last_year)).to eq(expected_last_year)
      expect(assigns(:fiscal_years)).to start_with([fiscal_year(expected_first_year), expected_first_year]).and end_with([fiscal_year(expected_last_year), expected_last_year])
      expect(assigns(:data)[:data][0][0]).to eq(fiscal_year(expected_first_year))
      expect(assigns(:data)[:data][-1][0]).to eq(fiscal_year(expected_last_year))
    end

    it 'config fy_year (manual rollover)' do
      SystemConfig.instance.update(fy_year: expected_first_year - 1)
      get :index
      expect(assigns(:first_year)).to eq(expected_first_year)
      expect(assigns(:last_year)).to eq(expected_last_year)
      expect(assigns(:fiscal_years)).to start_with([fiscal_year(expected_first_year), expected_first_year]).and end_with([fiscal_year(expected_last_year), expected_last_year])
      expect(assigns(:data)[:data][0][0]).to eq(fiscal_year(expected_first_year))
      expect(assigns(:data)[:data][-1][0]).to eq(fiscal_year(expected_last_year))
    end

    it 'rollover fy_year' do
      SystemConfig.instance.update(fy_year: expected_first_year)
      get :index
      expect(assigns(:first_year)).to eq(expected_first_year + 1)
      expect(assigns(:last_year)).to eq(expected_last_year + 1)
      expect(assigns(:fiscal_years)).to start_with([fiscal_year(expected_first_year + 1), expected_first_year + 1]).and end_with([fiscal_year(expected_last_year + 1), expected_last_year + 1])
      expect(assigns(:data)[:data][0][0]).to eq(fiscal_year(expected_first_year + 1))
      expect(assigns(:data)[:data][-1][0]).to eq(fiscal_year(expected_last_year + 1))
    end

    it 'config fy_year too far behind (manual rollover)' do
      SystemConfig.instance.update(fy_year: expected_first_year - 3)
      get :index
      expect(assigns(:first_year)).to eq(expected_first_year)
      expect(assigns(:last_year)).to eq(expected_last_year)
      expect(assigns(:fiscal_years)).to start_with([fiscal_year(expected_first_year), expected_first_year]).and end_with([fiscal_year(expected_last_year), expected_last_year])
      expect(assigns(:data)[:data][0][0]).to eq(fiscal_year(expected_first_year))
      expect(assigns(:data)[:data][-1][0]).to eq(fiscal_year(expected_last_year))
    end

    it 'reset config (automatic rollover)' do
      SystemConfig.instance.update(fy_year: nil)
      get :index
      expect(assigns(:first_year)).to eq(expected_first_year)
      expect(assigns(:last_year)).to eq(expected_last_year)
      expect(assigns(:fiscal_years)).to start_with([fiscal_year(expected_first_year), expected_first_year]).and end_with([fiscal_year(expected_last_year), expected_last_year])
      expect(assigns(:data)[:data][0][0]).to eq(fiscal_year(expected_first_year))
      expect(assigns(:data)[:data][-1][0]).to eq(fiscal_year(expected_last_year))
    end
  end

  it 'GET show' do
    get :show, params:{:id => test_project.object_key}


    expect(assigns(:project)).to eq(test_project)
  end

  it 'GET new' do
    get :new

    expect(assigns(:project).to_json).to eq(CapitalProject.new.to_json)
    expect(assigns(:fiscal_years))
  end
  it 'GET edit' do
    get :edit, params:{:id => test_project.object_key}

    expect(assigns(:project)).to eq(test_project)
    expect(assigns(:fiscal_years))
  end

  it 'POST copy' do
    pending('TODO')
    fail
  end

  it 'POST create' do
    test_type = CapitalProjectType.first
    test_ali = create(:replacement_ali_code, :parent => create(:replacement_ali_code))
    post :create, params:{ :capital_project => attributes_for(:capital_project, :organization => nil, :capital_project_type_id => test_type.id, :team_ali_code_id => test_ali.id)}

    expect(assigns(:organization).capital_projects.count).to eq(1)
  end

  it 'POST update' do
    request.env["HTTP_REFERER"] = root_path
    
    post :update, params: {:id => test_project.object_key, :capital_project => {:title => 'captial project title 222'}}
    test_project.reload

    expect(assigns(:project)).to eq(test_project)
    expect(test_project.title).to eq('captial project title 222')
    expect(assigns(:fiscal_years))
  end

  it 'DELETE destroy' do
    delete :destroy, params:{ :id => test_project.object_key}

    expect(CapitalProject.find_by(:object_key=>test_project.object_key)).to be nil
  end
end
