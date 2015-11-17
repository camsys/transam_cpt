FactoryGirl.define do

  factory :milestone do
    association :activity_line_item
    milestone_type_id 1
    milestone_date Date.today
  end

end
