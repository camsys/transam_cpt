require 'rails_helper'

describe "capital_projects/_index_actions.html.haml", :type => :view do
  it 'actions' do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    test_proj = create(:capital_project)
    assign(:organization_list, [test_proj.organization, create(:organization)])
    assign(:fiscal_years, [test_proj.fy_year])
    assign(:fiscal_year_filter, test_proj.fy_year)
    render

    expect(rendered).to have_link('New Capital Project')
    expect(rendered).to have_link('Export list to Excel')
    expect(rendered).to have_field('fiscal_year_filter')
    expect(rendered).to have_field('capital_project_flag_filter')
    expect(rendered).to have_field('capital_project_type_filter')
    expect(rendered).to have_field('asset_subtype_filter')
  end
end
