require 'rails_helper'

describe "capital_projects/_capital_plan_summary.html.haml", :type => :view do
  it 'list' do
    test_proj = create(:capital_project, :fy_year => 2010)
    assign(:years, [2010])
    assign(:projects, [test_proj])
    render

    expect(rendered).to have_content('FY 10-11')
    expect(rendered).to have_content('$0')
  end
end