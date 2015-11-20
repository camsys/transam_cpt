FactoryGirl.define do

  factory :activity_line_item do
  	capital_project
    name 'Activity line item 1'
    fy_year 2014
    team_ali_code { FactoryGirl.create(:replacement_ali_code, :parent => FactoryGirl.create(:replacement_ali_code)) }
  end

end
