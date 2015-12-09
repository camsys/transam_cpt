require 'rails_helper'

describe "capital_projects/_activity_line_items.html.haml", :type => :view do
  before(:each) do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    assign(:project, create(:capital_project))
  end

  it 'no alis' do
    render

    expect(rendered).to have_content('There are no activity line items for this project.')
  end
  it 'add ali' do
    render

    expect(rendered).to have_link('Add Line Item')
  end
end
