require 'rails_helper'

class TestOrg < Organization
  def get_policy
    return Policy.where("`organization_id` = ?",self.id).order('created_at').last
  end
end

RSpec.describe CapitalProjectBuilder do
  let(:policy) { create(:policy) }
  let(:asset) { create(:buslike_asset) }
  let(:organization) { asset.organization }
  let(:activity_line_item) { create(:activity_line_item) }

  it "builds a capital project" do
    pending "Don't have sufficient factories in place to support yet"
    cpb = CapitalProjectBuilder.new
    project_count = cpb.build(organization, asset_type_ids: [asset.asset_type])
    expect(project_count).to eql(1)
  end

	it "moves an ALI to a new planning year" do
    # TODO This is not complete by any stretch
		expect(activity_line_item.assets.count).to eq(3)
		cpb = CapitalProjectBuilder.new
		cpb.move_ali_to_planning_year activity_line_item, 2015
    # expect(activity_line_item.fy_year).to eql(2015)
	end
end
