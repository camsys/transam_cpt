require 'rails_helper'

describe "funding_requests/_index_table.html.haml", :type => :view do
  it 'list', :skip do
    test_fund = create(:funding_request)
    render 'funding_requests/index_table', :funding_requests => [test_fund]

    expect(rendered).to have_content(test_fund.fy_federal)
  end
end
