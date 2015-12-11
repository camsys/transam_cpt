require 'rails_helper'

describe "planning/_add_funds_modal_form.html.haml", :type => :view do
  it 'fields' do
    assign(:ali, create(:activity_line_item))
    assign(:fiscal_year, Date.today.year)
    assign(:budget_amounts, [])
    render

    expect(rendered).to have_xpath('//input[@id="fiscal_year"]')
    expect(rendered).to have_field('source')
    expect(rendered).to have_field('amount')
  end
end
