require 'rails_helper'

describe "planning/_pager.html.haml", :type => :view do
  it 'fiscal years' do
    assign(:prev_year, 2010)
    assign(:next_year, 2012)
    render

    expect(rendered).to have_content('FY 10-11')
    expect(rendered).to have_content('FY 12-13')
  end
end
