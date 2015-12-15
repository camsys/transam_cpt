require 'rails_helper'

describe "activity_line_items/_assets.html.haml", :type => :view do
  it 'no assets' do
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_content('There are no assets for this activity line item.')
  end
end
