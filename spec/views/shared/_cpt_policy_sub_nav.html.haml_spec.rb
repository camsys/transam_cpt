require 'rails_helper'

describe "shared/_cpt_policy_sub_nav.html.haml", :type => :view do
  it 'menu' do
    test_user = create(:admin)
    allow(controller).to receive(:current_user).and_return(test_user)
    allow(controller).to receive(:current_ability).and_return(Ability.new(test_user))
    render

    expect(rendered).to have_link('Capital Projects')
    expect(rendered).to have_link('Project Planner')
    expect(rendered).to have_link('New Capital Project')
    expect(rendered).to have_link('SOGR Capital Project Analyzer')
  end
end
