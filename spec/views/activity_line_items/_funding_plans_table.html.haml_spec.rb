require 'rails_helper'

describe "activity_line_items/_funding_plans_table.html.haml", :skip, :type => :view do
  before(:each) do
    assign(:project, create(:capital_project))
  end
  it 'no funding plans' do
    render 'activity_line_items/funding_plans_table', :ali => create(:activity_line_item), :popup => false

    expect(rendered).to have_content('There are no funding plans for this ALI.')
  end
  it 'list' do
    test_ali = create(:activity_line_item)
    test_plan = create(:funding_plan, :activity_line_item => test_ali, :amount => 12345)
    render 'activity_line_items/funding_plans_table', :ali => test_ali, :popup => false

    expect(rendered).to have_content('$12,345')
  end
  it 'popup true' do
    pending('TODO')
    fail
  end
end
