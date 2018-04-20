require 'rails_helper'

describe "reports/_capital_projects_report_summary.html.haml", :type => :view do
  it 'list' do
    allow(controller).to receive(:params).and_return({controller: 'reports'})
    test_proj = create(:capital_project)
    create(:activity_line_item, :capital_project => test_proj)
    render 'reports/capital_projects_report_summary', :projects => [test_proj]

    expect(rendered).to have_content('1')
    expect(rendered).to have_content(test_proj.project_number)
  end
end
