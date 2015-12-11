require 'rails_helper'

describe "funding_requests/_index_actions.html.haml", :type => :view do
  it 'actions', :skip do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    test_proj = create(:capital_project)
    assign(:organization_list, [test_proj.organization, create(:organization)])
    assign(:fiscal_years, [test_proj.fy_year])
    assign(:fiscal_year, test_proj.fy_year)
    assign(:capital_project_state, test_proj.state)
    assign(:capital_project_type_id, test_proj.capital_project_type_id)
    assign(:funding_source_id, create(:funding_source).id)
    render

    expect(rendered).to have_link('Export list to Excel')
    expect(rendered).to have_field('org_id')
    expect(rendered).to have_field('fiscal_year')
    expect(rendered).to have_field('capital_project_state')
    expect(rendered).to have_field('capital_project_type_id')
    expect(rendered).to have_field('funding_source_id')
  end
end
