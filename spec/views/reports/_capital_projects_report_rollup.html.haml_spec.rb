require 'rails_helper'

describe "reports/_capital_projects_report_rollup.html.haml", :type => :view do
  it 'info' do
    test_org = create(:organization)
    test_funding_source = create(:funding_source)
    test_proj = create(:capital_project, :organization => test_org)
    report = CapitalProjectsReport.new
    data = report.get_data(test_org, {:funding_source => test_funding_source})
    assign(:data, data)
    render

    expect(rendered).to have_content(test_org.short_name)
    expect(rendered).to have_content(1)
    expect(rendered).to have_content('$0')
  end
end
