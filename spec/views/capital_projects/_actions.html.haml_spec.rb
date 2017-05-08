require 'rails_helper'

describe "capital_projects/_actions.html.haml", :type => :view do
  it 'actions' do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    assign(:project, create(:capital_project))
    render

    expect(rendered).to have_link('Modify this project')
    expect(rendered).to have_link('Remove this project')
  end
end
