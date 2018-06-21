require 'rails_helper'

describe "planning/_pager.html.haml", :type => :view do
  it 'fiscal years' do
    skip 'Route error and also no longer used.'
    allow(controller).to receive(:params).and_return({controller: 'planning'})
    assign(:prev_year, 2010)
    assign(:next_year, 2012)
    render

    expect(rendered).to have_content('FY 10-11')
    expect(rendered).to have_content('FY 12-13')
  end
end
