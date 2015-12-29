require 'rails_helper'

describe "scheduler/_asset_detail.html.haml", :type => :view do
  it 'details' do
    if AssetType.count == 0 || AssetSubtype.count == 0
      AssetType.first
      AssetSubtype.first
    end
    test_asset = create(:buslike_asset, :asset_tag => 'TAG123')
    render 'scheduler/asset_detail', :asset => test_asset, :year => Date.today.year

    expect(rendered).to have_content('TAG123')
    expect(rendered).to have_content(test_asset.asset_subtype.to_s.upcase)
  end
end
