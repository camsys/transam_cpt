FactoryGirl.define do
    
  factory :activity_line_item do
  	capital_project
    name 'Activity line item 1'
    team_ali_code
    after(:build) do |ali|
      3.times do
        ali.assets << create(:buslike_asset)
      end
    end
  end

end
