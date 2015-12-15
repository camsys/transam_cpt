require 'rails_helper'

describe "activity_line_items/_milestones_form.html.haml", :type => :view do
  it 'form' do
    test_ali = create(:activity_line_item)
    create(:milestone, :activity_line_item => test_ali)
    test_ali.reload
    assign(:project, create(:capital_project))
    assign(:activity_line_item, test_ali)
    render

    expect(rendered).to have_xpath('//input[@id ="activity_line_item_milestones_attributes_0_id"]')
    expect(rendered).to have_xpath('//input[@id ="activity_line_item_milestones_attributes_0_object_key"]')
    expect(rendered).to have_xpath('//input[@id ="activity_line_item_milestones_attributes_0_milestone_type_id"]')
    expect(rendered).to have_field('activity_line_item_milestones_attributes_0_milestone_date')
    expect(rendered).to have_field('activity_line_item_milestones_attributes_0_comments')
  end
end
