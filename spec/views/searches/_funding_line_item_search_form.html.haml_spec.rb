require 'rails_helper'

describe "searches/_funding_line_item_search_form.html.haml", :skip, :type => :view do
  it 'fields', :skip do
    assign(:organization_list, [1,2,3])
    assign(:searcher, FundingLineItemSearcher.new)
    render

    expect(rendered).to have_field('searcher_organization_id')
    expect(rendered).to have_field('searcher_fy_year')
    expect(rendered).to have_field('searcher_funding_line_item_type')
    expect(rendered).to have_field('searcher_amount')
    expect(rendered).to have_field('searcher_amount comparator')
    expect(rendered).to have_field('searcher_funding_source_type')
    expect(rendered).to have_field('searcher_discretionary_type')
  end
end
