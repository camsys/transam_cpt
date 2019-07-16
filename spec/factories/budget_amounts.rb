FactoryBot.define do

  factory :budget_amount do
    organization
    funding_source
    fy_year { Date.today.year }
  end

end
