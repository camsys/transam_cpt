require 'rails_helper'

describe "planning/_asset_detail.html.haml", :type => :view do
  it 'asset' do
    if AssetType.count == 0 || AssetSubtype.count == 0
      create(:asset_type)
      create(:asset_subtype)
    end
    test_asset = create(:buslike_asset, :estimated_condition_type_id => 6)
    render 'planning/asset_detail', :asset => test_asset, :year => Date.today.year

    expect(rendered).to have_content(test_asset.asset_subtype.to_s.upcase)
    expect(rendered).to have_content('Condition: 2.00')
  end
end
