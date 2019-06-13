require 'rails_helper'

describe "capital_projects/_index_table.html.haml", :type => :view do
  it 'list' do
    allow(controller).to receive(:current_user).and_return(create(:admin))
    test_proj = create(:capital_project, :fy_year => 2010)
    assign(:projects, [test_proj])
    assign(:organization_list, [test_proj.organization])
    controller.request.path_parameters[:action] = 'index'
    render
  end
end
