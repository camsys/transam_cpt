require 'rails_helper'

describe "capital_projects/_history_table.html.haml", :type => :view do
  it 'no history' do
    test_proj = create(:capital_project)
    assign(:project, test_proj)

    render

    expect(rendered).to have_content('There are no workflow events associated with this project.')
  end
  it 'history list' do
    test_admin = create(:admin)
    test_proj = create(:capital_project)
    WorkflowEvent.create!(:accountable_id => test_proj.id, :accountable_type => 'CapitalProject', :event_type => 'submit', :created_by_id => test_admin.id)
    assign(:project, test_proj)
    render

    expect(rendered).to have_content(Date.today.strftime('%m/%d/%Y'))
    expect(rendered).to have_content('Submit')
    expect(rendered).to have_content(test_admin.name)
  end
end
