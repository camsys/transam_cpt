require 'rails_helper'

describe "capital_projects/_builder_form.html.haml", :type => :view do
  it 'fields' do
    assign(:builder_proxy, BuilderProxy.new)
    assign(:asset_types, AssetType.all)
    assign(:fiscal_years, [['FY 10-11', 2010], ['FY 11-12', 2012]])
    assign(:organization, create(:organization))
    assign(:organization_list,[1,2])
    render

    expect(rendered).to have_field('builder_proxy_organization_id')
    expect(rendered).to have_xpath('//input[@name="builder_proxy[fta_asset_classes][]"]')
    expect(rendered).to have_field('builder_proxy_start_fy')
  end
end
