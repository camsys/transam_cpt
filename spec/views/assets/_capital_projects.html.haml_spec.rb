require 'rails_helper'

describe "assets/_capital_projects.html.haml", :type => :view do
  it 'no projects' do
    assign(:asset, create(:buslike_asset, :asset_type => create(:asset_type), :asset_subtype => create(:asset_subtype)))
    render

    expect(rendered).to have_content('This asset is not associated with any capital projects')
  end
end
