require 'rails_helper'

describe "reports/_capital_projects_report_actions.html.haml", :type => :view do
  it 'actions' do
    test_org = create(:organization)
    report = CapitalProjectsReport.new
    assign(:report, report)
    assign(:organization_list, [test_org, create(:organization)])
    data = report.get_data(test_org, {:funding_source => create(:funding_source)})
    assign(:data, data)
    render

    expect(rendered).to have_field('fy_year')
    expect(rendered).to have_field('emergency_flag')
    expect(rendered).to have_field('multi_year_flag')
    expect(rendered).to have_field('sogr_flag')
  end
end
