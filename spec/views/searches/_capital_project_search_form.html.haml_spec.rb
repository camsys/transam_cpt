require 'rails_helper'

describe "searches/_capital_project_search_form.html.haml", :skip, :type => :view do
  it 'fields' do
    test_admin = create(:admin)
    3.times do
      test_admin.organizations << create(:organization)
    end
    test_admin.save!
    allow(controller).to receive(:current_user).and_return(test_admin)
    assign(:searcher, CapitalProjectSearcher.new)
    render

    expect(rendered).to have_field('searcher_keyword')
    expect(rendered).to have_field('searcher_organization_id')
    expect(rendered).to have_field('searcher_total_cost')
    expect(rendered).to have_field('searcher_fy_year')
    expect(rendered).to have_field('searcher_capital_project_state')
    expect(rendered).to have_field('searcher_capital_project_type')
    expect(rendered).to have_field('searcher_team_ali_code')
    expect(rendered).to have_field('searcher_funding_source')
    expect(rendered).to have_field('searcher_asset_type')
    expect(rendered).to have_field('searcher_asset_subtype')
  end
end
