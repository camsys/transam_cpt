require 'rails_helper'

describe "capital_projects/_form.html.haml", :type => :view do
  it 'fields' do
    assign(:project, CapitalProject.new)
    assign(:organization_list, [1,2])
    render

    expect(rendered).to have_field('capital_project_organization_id')
    expect(rendered).to have_field('capital_project_title')
    expect(rendered).to have_field('capital_project_fy_year')
    expect(rendered).to have_field('capital_project_team_ali_code_id')
    expect(rendered).to have_field('capital_project_capital_project_type_id')
    expect(rendered).to have_field('capital_project_emergency')
    expect(rendered).to have_field('capital_project_multi_year')
    expect(rendered).to have_field('capital_project_description')
    expect(rendered).to have_field('capital_project_justification')
  end
end
