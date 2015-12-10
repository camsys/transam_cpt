require 'rails_helper'

describe "shared/_cpt_main_nav.html.haml", :type => :view do
  it 'menu' do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    render

    expect(rendered).to have_link('Capital Projects')
    expect(rendered).to have_link('Project planner')
    expect(rendered).to have_link('New Capital Project')
    expect(rendered).to have_link('SOGR Capital Project Analyzer')
  end
end
