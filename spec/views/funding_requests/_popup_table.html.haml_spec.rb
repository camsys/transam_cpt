require 'rails_helper'

describe "funding_requests/_popup_table.html.haml", :type => :view do
  it 'list', :skip do
    test_proj = create(:capital_project)
    test_ali = create(:activity_line_item)
    test_funding_request = create(:funding_request, :activity_line_item => test_ali)
    test_funding_line_item = create(:funding_line_item, :funding_request => test_funding_request)
    render 'funding_requests/popup_table', :funding_line_item => test_funding_line_item

    expect(rendered).to have_content(test_proj.to_s)
    expect(rendered).to have_content(test_funding_request.federal_amount)
  end
end
