require 'rails_helper'

describe "funding_requests/index.html.haml", :type => :view do
  it 'no funding requests', :skip do
    assign(:funding_requests, [])
    render

    expect(rendered).to have_content('No matching funding requests found')
  end
end
