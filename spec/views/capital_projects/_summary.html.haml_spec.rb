require 'rails_helper'

describe "capital_projects/_summary.html.haml", :type => :view do
  it 'list' do
    test_proj = create(:capital_project, :fy_year => 2010)
    assign(:project, test_proj)
    render

    expect(rendered).to have_content(test_proj.project_number)
    expect(rendered).to have_content('FY 10-11')
    expect(rendered).to have_content(test_proj.capital_project_type.to_s)
  end
end
