require 'rails_helper'

describe "activity_line_items/_cost_justification.html.haml", :type => :view do
  it 'no justification' do
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_content('No cost justification has been provided.')
  end
  it 'justification' do
    assign(:activity_line_item, create(:activity_line_item, :cost_justification => 'justify ali 123'))
    render

    expect(rendered).to have_content('justify ali 123')
  end
end
