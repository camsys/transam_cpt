require 'rails_helper'

describe "activity_line_items/_summary.html.haml", :type => :view do
  it 'info' do
    test_ali = create(:activity_line_item, :anticipated_cost => 12345)
    render 'activity_line_items/summary', :ali => test_ali

    expect(rendered).to have_link(test_ali.capital_project.project_number)
    expect(rendered).to have_content('$12,345')
  end
end
