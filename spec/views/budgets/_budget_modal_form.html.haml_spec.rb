require 'rails_helper'

describe "budgets/_budget_modal_form.html.haml", :type => :view do
  it 'fields', :skip do
    assign(:funding_source, create(:funding_source))
    assign(:organization, create(:organization))
    assign(:budget, [12000])
    render

    expect(rendered).to have_xpath('//input[@id="funding_source"]')
    expect(rendered).to have_xpath('//input[@id="org_id"]')
    expect(rendered).to have_field((Date.today.year+1).to_s)
  end
end
