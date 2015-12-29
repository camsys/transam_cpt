require 'rails_helper'

describe "scheduler/_edit_asset_in_modal.html.haml", :type => :view do
  it 'fields' do
    if AssetType.count == 0 || AssetSubtype.count == 0
      AssetType.first
      AssetSubtype.first
    end
    assign(:proxy, SchedulerActionProxy.new)
    assign(:asset_subtype_id, 1)
    assign(:org_id, create(:organization).id)
    assign(:active_year, Date.today.year)
    assign(:actions, [1,2,3])
    assign(:fiscal_years,[Date.today.year-1,Date.today.year])
    assign(:asset, create(:buslike_asset))
    render

    expect(rendered).to have_field('scheduler_action_proxy_action_id')
    expect(rendered).to have_field('scheduler_action_proxy_fy_year')
    expect(rendered).to have_field('scheduler_action_proxy_reason_id')
    expect(rendered).to have_field('scheduler_action_proxy_replace_with_new')
    expect(rendered).to have_field('scheduler_action_proxy_replace_cost')
    expect(rendered).to have_field('scheduler_action_proxy_rehab_cost')
    expect(rendered).to have_field('scheduler_action_proxy_replace_subtype_id')
    expect(rendered).to have_field('scheduler_action_proxy_replace_fuel_type_id')
    expect(rendered).to have_field('scheduler_action_proxy_extend_eul_years')
  end
end
