require 'rails_helper'

describe "scheduler/_update_cost_modal.html.haml", :type => :view do
  it 'fields' do
    assign(:ali, create(:activity_line_item))
    assign(:active_year, Date.today.year)
    render

    expect(rendered).to have_xpath('//input[@id="active_year"]')
    expect(rendered).to have_field('activity_line_item_anticipated_cost')
    expect(rendered).to have_field('activity_line_item_cost_justification')
  end
end
