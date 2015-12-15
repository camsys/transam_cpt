require 'rails_helper'

describe "activity_line_items/_comments.html.haml", :type => :view do
  it 'no comments' do
    test_user = create(:admin)
    allow(controller).to receive(:current_ability).and_return(Ability.new(test_user))
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_content('There are no comments for this activity line item.')
  end
end
