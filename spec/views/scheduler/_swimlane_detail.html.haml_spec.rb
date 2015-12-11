require 'rails_helper'

describe "scheduler/_swimlane_detail.html.haml", :type => :view do
  it 'swimlane', :skip do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    test_org = create(:organization)
    test_ali = create(:activity_line_item)
    test_budget_amount = create(:budget_amount, :organization => test_org)
    test_funding_plan = create(:funding_plan, :activity_line_item => test_ali, :budget_amount => test_budget_amount)
    assign(:fiscal_year, Date.today.year)
    assign(:prev_year, Date.today.year-1)
    assign(:next_year, Date.today.year+1)
    render 'scheduler/swimlane_detail', :ali => test_ali

    expect(rendered).to have_link('Update ALI cost')
    expect(rendered).to have_link('Assign Funds')
    expect(rendered).to have_link('Remove ALI')
    expect(rendered).to have_content('There are no assets associated with this ALI')
    expect(rendered).to have_content(test_budget_amount.funding_source.to_s)
  end
end
