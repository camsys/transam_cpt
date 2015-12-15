require 'rails_helper'

describe "capital_projects/_activity_line_items_table.html.haml", :type => :view do
  it 'list' do
    test_proj = create(:capital_project, :fy_year => 2014)
    test_ali = create(:activity_line_item, :capital_project => test_proj)
    render 'capital_projects/activity_line_items_table', :project => test_proj

    expect(rendered).to have_content(test_ali.name)
    expect(rendered).to have_content('FY 14-15')
  end
end