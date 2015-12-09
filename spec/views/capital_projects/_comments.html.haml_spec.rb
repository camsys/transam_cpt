require 'rails_helper'

describe "capital_projects/_comments.html.haml", :type => :view do
  before(:each) do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    assign(:project, create(:capital_project))
  end

  it 'no comments' do
    render

    expect(rendered).to have_content('There are no comments for this project.')
  end
  it 'add comment' do
    render
    
    expect(rendered).to have_content('Add Comment')
  end
end
