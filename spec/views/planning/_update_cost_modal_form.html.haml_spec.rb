require 'rails_helper'

describe "planning/_update_cost_modal_form.html.haml", :type => :view do
  it 'fields' do
    assign(:ali, create(:activity_line_item))
    assign(:fiscal_year, Date.today.year)
    render

    expect(rendered).to have_field('activity_line_item_anticipated_cost')
  end
end
