require 'rails_helper'

describe "planning/_ali.html.haml", :type => :view do
  it 'actions' do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    test_ali = create(:activity_line_item, :anticipated_cost => 23456)
    render 'planning/ali', :project => test_ali.capital_project, :ali => test_ali

    expect(rendered).to have_content(test_ali.name)
    expect(rendered).to have_content(test_ali.team_ali_code.to_s)
    expect(rendered).to have_content('$23,456')
  end
end
