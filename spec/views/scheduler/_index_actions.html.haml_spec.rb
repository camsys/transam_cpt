require 'rails_helper'

describe "scheduler/_index_actions.html.haml", :type => :view do
  it 'actions' do
    assign(:organization_list, [create(:organization).id, create(:organization).id])
    render

    expect(rendered).to have_link('Export this plan to Excel')
  end
end
