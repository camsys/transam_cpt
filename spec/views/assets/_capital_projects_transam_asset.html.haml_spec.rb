require 'rails_helper'

# Survivor-hierarchy mirror (TTPLAT-3090) of spec/views/assets/_capital_projects.html.haml_spec.rb.
# Liveness: the partial is rendered by app/views/assets/_cpt_detail_tabs_content.html.haml:3
# (render 'capital_projects'), which core's assets/_details.html.haml loads by module name.
describe "assets/_capital_projects.html.haml", :type => :view do
  let(:test_org) { create(:organization) }
  let(:test_subtype) { AssetSubtype.first }
  let(:test_asset) do
    create(:parent_policy, :organization => test_org, :type => test_subtype.asset_type_id, :subtype => test_subtype.id, :has_fuel_type => false)
    create(:transam_asset, :organization => test_org, :asset_subtype => test_subtype)
  end

  # Mirrors: spec/views/assets/_capital_projects.html.haml_spec.rb:5-11 ('no projects';
  # skipped :5 'Assumes transam_asset', so it never ran).
  it 'no projects' do
    assign(:asset, test_asset)
    render

    expect(rendered).to have_content('This asset is not associated with any capital projects')
  end
end
