require 'rails_helper'

describe "searches/_funding_source_search_form.html.haml", :type => :view do
  it 'fields' do
    assign(:searcher, FundingSourceSearcher.new)
    render

    expect(rendered).to have_field('searcher_keyword')
    expect(rendered).to have_field('searcher_funding_source_type_id')
    expect(rendered).to have_field('searcher_federal_match_required')
    expect(rendered).to have_field('searcher_state_match_required')
    expect(rendered).to have_field('searcher_local_match_required')
    expect(rendered).to have_field('searcher_state_administered_federal_fund')
    expect(rendered).to have_field('searcher_rural_providers')
    expect(rendered).to have_field('searcher_urban_providers')
    expect(rendered).to have_field('searcher_shared_ride_providers')
    expect(rendered).to have_field('searcher_inter_city_bus_providers')
    expect(rendered).to have_field('searcher_inter_city_rail_providers')
    expect(rendered).to have_field('searcher_show_inactive')
  end
end
