require 'rails_helper'

describe "planning/_fund_detail.html.haml", :type => :view do
  it 'fund' do
    test_fund = create(:funding_source)
    assign(:organization, create(:organization))
    assign(:first_year, Date.today.year)
    render 'planning/fund_detail', :fund => test_fund, :year => Date.today.year

    expect(rendered).to have_content(test_fund.name)
  end
end
