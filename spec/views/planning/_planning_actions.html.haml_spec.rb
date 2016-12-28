require 'rails_helper'

describe "planning/_planning_actions.html.haml", :type => :view do
  it 'actions' do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    render

    expect(rendered).to have_link('New Capital Project')
  end
end
