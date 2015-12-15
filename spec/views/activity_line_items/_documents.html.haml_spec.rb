require 'rails_helper'

describe "activity_line_items/_documents.html.haml", :type => :view do
  it 'no comments' do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_content('There are no documents for this activity line item.')
  end
end
