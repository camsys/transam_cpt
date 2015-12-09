require 'rails_helper'

describe "capital_projects/_documents.html.haml", :type => :view do
  before(:each) do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    assign(:project, create(:capital_project))
  end

  it 'no documents' do
    render

    expect(rendered).to have_content('There are no documents for this project.')
  end
  it 'add document' do
    render
    
    expect(rendered).to have_content('Add Document')
  end
end
