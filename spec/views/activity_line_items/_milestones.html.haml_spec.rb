require 'rails_helper'

describe "activity_line_items/_milestones.html.haml", :type => :view do
  it 'no milestones' do
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_content('There are no milestones for this activity line item.')
  end
  it 'list' do
    test_ali = create(:activity_line_item)
    test_milestone = create(:milestone, :activity_line_item => test_ali, :comments => 'test milestone comment 246')
    assign(:activity_line_item, test_ali)
    render

    expect(rendered).to have_content(test_milestone.milestone_type.to_s)
    expect(rendered).to have_content(Date.today.strftime('%m/%d/%Y'))
    expect(rendered).to have_content('test milestone comment 246')
  end
end
