require 'rails_helper'

describe "capital_projects/_builder_form.html.haml", :type => :view do
  it 'fields' do
    assign(:builder_proxy, BuilderProxy.new)
    assign(:asset_types, AssetType.all)
    assign(:fiscal_years, [2010])
    assign(:organization, create(:organization))
    render

    expect(rendered).to have_xpath('//input[@name="builder_proxy[asset_types][]"]')
    expect(rendered).to have_field('builder_proxy_start_fy')
  end
end
