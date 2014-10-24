require 'rails_helper'

RSpec.describe CapitalProjectBuilder do
    let(:activity_line_item) { create(:activity_line_item) }

	it "moves an ALI to a new planning year" do
		expect(activity_line_item.assets.count).to eq(3)
		cpb = CapitalProjectBuilder.new
		cpb.move_ali_to_planning_year activity_line_item, '2015'
	end
end
