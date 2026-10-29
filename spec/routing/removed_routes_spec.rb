require "rails_helper"

# TTPLAT-3091 instance 9: the ALI add_asset / remove_asset routes were removed
# with their (unused) controller actions. Ask the router directly, not the controller.
RSpec.describe "Removed routes", type: :routing do

  it 'no longer routes GET /capital_projects/:capital_project_id/activity_line_items/:id/add_asset' do
    expect(:get => '/capital_projects/abc/activity_line_items/def/add_asset').not_to be_routable
  end

  it 'no longer routes DELETE /capital_projects/:capital_project_id/activity_line_items/:id/remove_asset' do
    expect(:delete => '/capital_projects/abc/activity_line_items/def/remove_asset').not_to be_routable
  end
end
