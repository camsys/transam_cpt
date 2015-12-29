require 'rails_helper'

describe "planning/_edit_asset_modal_form.html.haml", :type => :view do
  it 'fields' do
    allow(controller).to receive(:current_ability).and_return(Ability.new(create(:admin)))
    assign(:proxy, SchedulerActionProxy.new)
    assign(:fiscal_year, Date.today.year)
    assign(:fiscal_years, [Date.today.year-1, Date.today.year])
    assign(:actions, [1,2,3])
    assign(:asset, create(:buslike_asset, :asset_type => AssetType.first, :asset_subtype => AssetSubtype.first))
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
