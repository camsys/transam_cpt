require 'rails_helper'

describe "activity_line_items/_form.html.haml", :type => :view do
  it 'fields' do
    assign(:project, create(:capital_project, :multi_year => true))
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_field('activity_line_item_name')
    expect(rendered).to have_field('activity_line_item_anticipated_cost')
    expect(rendered).to have_field('activity_line_item_fy_year')
    expect(rendered).to have_field('activity_line_item_category_team_ali_code')
    expect(rendered).to have_field('activity_line_item_team_ali_code_id')
  end
end
