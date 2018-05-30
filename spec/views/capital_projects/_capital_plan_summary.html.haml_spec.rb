require 'rails_helper'

describe "capital_projects/_capital_plan_summary.html.haml", :type => :view do
  it 'list' do
    allow(controller).to receive(:params).and_return({controller: 'capital_projects'})
    test_proj = create(:capital_project, :fy_year => 2010)
    assign(:years, [2010])
    assign(:projects, CapitalProject.where(id: test_proj.id))
    render

    expect(rendered).to have_content('FY 10-11')
    expect(rendered).to have_content('$0')
  end
end
