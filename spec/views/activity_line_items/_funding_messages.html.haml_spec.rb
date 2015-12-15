require 'rails_helper'

describe "activity_line_items/_funding_messages.html.haml", :type => :view do
  it 'no funds needed' do
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_content('This ALI is fully funded. No more funds can be added.')
  end
  it 'funds needed' do
    assign(:activity_line_item, create(:activity_line_item, :anticipated_cost => 12345))
    render

    expect(rendered).to have_content('You need an additional $12,345 to fund this ALI.')
  end
end
