require 'rails_helper'

describe "scheduler/_add_funding_plan_modal_form.html.haml", :type => :view do
  it 'fields' do
    assign(:ali, create(:activity_line_item))
    assign(:active_year, Date.today.year)
    assign(:funding_sources, [create(:funding_source)])
    render

    expect(rendered).to have_xpath('//input[@id="active_year"]')
    expect(rendered).to have_field('source')
    expect(rendered).to have_field('amount')
  end
end
