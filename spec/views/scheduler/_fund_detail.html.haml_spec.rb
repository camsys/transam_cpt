require 'rails_helper'

describe "scheduler/fund_detail.html.haml", :type => :view do
  it 'details', :skip do
    test_org = create(:organization)
    test_funding_source = create(:funding_source)
    test_budget = create(:budget_amount, :organization => test_org, :funding_source => test_funding_source, :fy_year => Date.today.year, :amount => 123456, :spent => 2345)
    assign(:organization, test_org)
    render

    expect(rendered).to have_content('$121,111')
    expect(rendered).to have_content('$2,345')
  end
end
