require 'rails_helper'

describe "planning/_activity_line_item_action_links.html.haml", :type => :view do
  it 'actions' do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    test_proj = create(:capital_project)
    render 'planning/activity_line_item_action_links', :project => test_proj, :ali => create(:activity_line_item, :capital_project => test_proj)

    expect(rendered).to have_link('Update the expected cost')
    expect(rendered).to have_link('Remove this ALI')
  end
end
