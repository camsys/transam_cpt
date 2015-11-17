FactoryGirl.define do

  factory :activity_line_item do
  	capital_project
    name 'Activity line item 1'
    team_ali_code { FactoryGirl.create(:team_ali_code, :parent => FactoryGirl.create(:team_ali_code)) }
  end

end
