require 'rails_helper'

describe "planning/_plan_project_detail.html.haml", :type => :view do
  it 'info and actions' do
    test_proj = create(:capital_project)
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    render 'planning/plan_project_detail', :project => test_proj

    expect(rendered).to have_link(test_proj.title)
    expect(rendered).to have_content(test_proj.project_number)
    expect(rendered).to have_link('Add Line Item')
    expect(rendered).to have_link('Edit')
    expect(rendered).to have_link('Remove')
  end
end
