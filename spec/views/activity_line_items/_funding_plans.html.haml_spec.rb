require 'rails_helper'

describe "activity_line_items/_funding_plans.html.haml", :type => :view do
  it 'form', :skip do
    assign(:project, create(:capital_project))
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_field('funding_plan_funding_source_id')
    expect(rendered).to have_field('funding_plan_amount')
  end
end
