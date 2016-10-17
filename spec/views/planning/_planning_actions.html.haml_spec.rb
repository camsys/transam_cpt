require 'rails_helper'

describe "planning/_planning_actions.html.haml", :type => :view do
  it 'actions' do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    test_proj = create(:capital_project)
    assign(:capital_project_type_id, test_proj.capital_project_type_id)
    assign(:capital_project_filter, test_proj.capital_project_type_id)
    assign(:org_filter, test_proj.organization_id)
    assign(:organization_list, [test_proj.organization_id, create(:organization).id])
    assign(:asset_subtype_filter, AssetType.first)
    render

    expect(rendered).to have_link('New Capital Project')
    # expect(rendered).to have_link('Export plan to Excel')
    expect(rendered).to have_field('capital_project_flag_filter')
    expect(rendered).to have_field('capital_project_type_filter')
    expect(rendered).to have_field('asset_subtype_filter')
  end
end
