require 'rails_helper'

describe "assets/_capital_projects.html.haml", :type => :view do
  it 'no projects' do
    assign(:asset, create(:buslike_asset, :asset_type => AssetType.first, :asset_subtype => AssetSubtype.first))
    render

    expect(rendered).to have_content('This asset is not associated with any capital projects')
  end
end
