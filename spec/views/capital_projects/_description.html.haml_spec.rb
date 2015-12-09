require 'rails_helper'

describe "capital_projects/_description.html.haml", :type => :view do
  it 'info' do
    assign(:project, create(:capital_project, :description => 'test description 12345', :justification => 'why we do this 6789'))
    render

    expect(rendered).to have_content('test description 12345')
    expect(rendered).to have_content('why we do this 6789')
  end
end
