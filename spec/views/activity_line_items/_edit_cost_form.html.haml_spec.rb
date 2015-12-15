require 'rails_helper'

describe "activity_line_items/_edit_cost_form.html.haml", :type => :view do
  it 'fields' do
    assign(:project, create(:capital_project))
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_field('activity_line_item_cost')
    expect(rendered).to have_field('activity_line_item_cost_justification')
  end
end
