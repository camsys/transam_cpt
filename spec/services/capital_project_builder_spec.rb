require 'rails_helper'
include FiscalYear

def show_asset asset
  puts
    puts asset.object_key
    puts "manufacture_year #{asset.manufacture_year}"
    puts "policy_replacement_year #{asset.policy_replacement_year}"
    puts "estimated_replacement_year #{asset.estimated_replacement_year}"
    puts "scheduled_replacement_year #{asset.scheduled_replacement_year}"
    puts "scheduled_rehabilitation_year #{asset.scheduled_rehabilitation_year}"
    puts "scheduled_disposition_year #{asset.scheduled_disposition_year}"
    puts "reported_condition_date #{asset.reported_condition_date}"
    puts "disposition_date #{asset.disposition_date}"
    puts "purchase_date #{asset.purchase_date}"
    puts "in_service_date #{asset.in_service_date}"
    puts "expected_useful_life #{asset.expected_useful_life}"
end

RSpec.describe CapitalProjectBuilder do

  let(:organization) { Organization.get_typed_organization(create(:organization))}
  let(:test_asset_type) {create(:asset_type)}
  let(:parent_ali_code) {create(:parent_ali_code)}
  let(:test_parent_policy) {create(:parent_policy,
                                   organization: organization,
                                   type: test_asset_type.id,
                                   subtype: create(:asset_subtype, asset_type: test_asset_type).id,
                                   replacement_code: create(:replacement_ali_code, parent: parent_ali_code),
                                   rehab_code: create(:rehabilitation_ali_code, parent: parent_ali_code))}
  let(:test_policy) {create(:policy, organization: organization, parent: test_parent_policy)}
  let(:test_asset1) {create(:transam_asset,
                            :organization => organization,
                            :asset_subtype => test_policy.parent.policy_asset_subtype_rules.first.asset_subtype)}
  let!(:test_asset2) {create(:transam_asset,
                            organization: organization,
                            asset_subtype: test_asset1.asset_subtype,
                            purchase_cost: 2000.0,
                            purchase_date: 2.years.ago,
                            policy_replacement_year: 2.years.from_now.year,
                            scheduled_rehabilitation_year: 2.years.from_now.year,
                            manufacture_year: 14.years.ago)}

  before(:all) do
    TeamAliCode.delete_all
  end

  before(:each) do
    # TODO I should note why I'm doing this here, not up in let()
    # policy = create(:policy, organization: organization)
    # create(:policy_asset_type_rule, :policy => policy, :asset_type => AssetSubtype.first.asset_type)
    # create(:policy_asset_subtype_rule, :policy => policy, :asset_subtype => AssetSubtype.first)

    # show_asset(asset)
    # show_asset(asset2)
    @cpb = CapitalProjectBuilder.new
  end

  it "adds assets as expected to new capital projects" do
    # Check first that we have no capital projects
    cps = CapitalProject.where(organization: organization).order(:fy_year)
    expect(cps.count).to eq(0)

    project_count = @cpb.build(organization, asset_subtype_id: test_asset1.asset_subtype.id)
    expect(project_count).to eql(2)
    #expect(project_count).to eql(4)

    cps = organization.capital_projects.order(:fy_year)
    #expect(cps.count).to eq(2)
    #expect(cps.count).to eq(4)

    expect(cps[0].fy_year).to eq(Date.today < start_of_fiscal_year(Date.today.year) ? Date.today.year : 1.year.from_now.year)
    expect(cps[1].fy_year).to eq(2.years.from_now.year)
    # expect(cps[2].fy_year).to eq(11.years.from_now.year)
    # expect(cps[3].fy_year).to eq(12.years.from_now.year)

    # show_asset(asset)
    # show_asset(asset2)

    expect(cps[0].activity_line_items.count).to eq(1)
    expect(cps[0].activity_line_items.first.assets.count).to eq(2)
    expect(cps[1].activity_line_items.count).to eq(1)
    expect(cps[1].activity_line_items.first.assets.count).to eq(1)

    expect(cps[0].activity_line_items.first.assets.first).to eq(test_asset1)
    expect(cps[1].activity_line_items.first.assets.first).to eq(test_asset2)
    # expect(cps[2].activity_line_items.first.assets.first).to eq(asset)
    # expect(cps[3].activity_line_items.first.assets.first).to eq(asset2)

  end

  it "moves an ALI to a new planning year which does not have a CP yet", :skip do
    project_count = @cpb.build(organization, asset_type_ids: [asset.asset_type])

    cp = CapitalProject.where(organization: organization).order(:fy_year)[1]
    ali = cp.activity_line_items.first

    result = @cpb.move_ali_to_planning_year(ali, cp.fy_year + 1)

    cps = organization.capital_projects.order(:fy_year)
    #expect(cps.count).to eq(2)
    #expect(cps.count).to eq(4)
    expect(cps[0].fy_year).to eq(1.year.from_now.year)
    expect(cps[1].fy_year).to eq((2+1).years.from_now.year)
    # expect(cps[2].fy_year).to eq(11.years.from_now.year)
    # # Note we only moved one of the ALIs, not both. This year doesn't change
    # expect(cps[3].fy_year).to eq(12.years.from_now.year)

    expect(cps[0].activity_line_items.first.assets.first).to eq(asset)
    expect(cps[1].activity_line_items.first.assets.first).to eq(asset2)
    # expect(cps[2].activity_line_items.first.assets.first).to eq(asset)
    # expect(cps[3].activity_line_items.first.assets.first).to eq(asset2)

  end

  # let(:activity_line_item) { create(:activity_line_item) }

  # it "moves an ALI to a new planning year" do
  #    # TODO This is not complete by any stretch
  #   expect(activity_line_item.assets.count).to eq(3)
  #   cpb = CapitalProjectBuilder.new
  #   cpb.move_ali_to_planning_year activity_line_item, 2015
  #    # expect(activity_line_item.fy_year).to eql(2015)
  # end
end
