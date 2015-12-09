require 'rails_helper'

describe "capital_projects/_summary_index_table.html.haml", :type => :view do
  it 'list' do
    test_proj = create(:capital_project, :fy_year => 2010)
    render 'capital_projects/summary_index_table', :projects => [test_proj]

    expect(rendered).to have_content(test_proj.project_number)
    expect(rendered).to have_content('FY 10-11')
    expect(rendered).to have_content(test_proj.capital_project_type.code)
  end
end
