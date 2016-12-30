require 'rails_helper'

describe "capital_projects/index.html.haml", :type => :view do
  it 'no projects' do
    test_user = create(:admin)
    allow(controller).to receive(:current_user).and_return(test_user)
    allow(controller).to receive(:current_ability).and_return(Ability.new(test_user))
    assign(:organization_list, [])
    assign(:fiscal_years, [2010])
    assign(:fiscal_year_filter, 2010)
    assign(:projects, CapitalProject.none)
    assign(:report, Report.new(:id => 1))
    assign(:years, [])
    assign(:data, {:labels => ['test_label'], :data => []})
    assign(:user_activity_line_item_filter, UserActivityLineItemFilter.new)
    render

    expect(rendered).to have_content('No matching capital projects found')
  end
end
