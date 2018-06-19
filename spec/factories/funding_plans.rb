FactoryBot.define do

  factory :funding_plan do
    association :activity_line_item
    association :funding_source
    amount 100
  end

end
