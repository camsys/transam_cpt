require 'rails_helper'

describe "planning/_assets_datatable.html.haml", :type => :view do
  it 'table' do
    skip 'Assumes transam_asset. Not yet testable.'
    allow(controller).to receive(:params).and_return({controller: 'planning'})
    if AssetType.count == 0 || AssetSubtype.count == 0
      AssetType.first
      AssetSubtype.first
    end
    test_proj = create(:capital_project)
    test_ali = create(:activity_line_item, :capital_project => test_proj)
    test_asset = create(:buslike_asset, :book_value => 111)
    test_ali.assets << test_asset
    test_ali.save!
    assign(:project, test_proj)
    assign(:activity_line_item, test_ali)
    assign(:fiscal_years, [Date.today.year, Date.today.year+1])
    render 'planning/assets_datatable', :ali => test_ali

    expect(rendered).to have_content('Move selected to FY')
    expect(rendered).to have_content(test_asset.object_key)
    expect(rendered).to have_content(test_asset.description)
  end
end
