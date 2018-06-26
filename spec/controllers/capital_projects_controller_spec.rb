require 'rails_helper'

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
    get :builder
  end

  it 'POST runner' do
    pending('TODO')
    fail
    post :runner
  end

  it 'GET index' do
    get :index
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
