FactoryBot.define do

  factory :capital_project do
    organization
    association :team_ali_code, :factory => :replacement_ali_code
    capital_project_type_id { 1 }
    fy_year { 2014 }
    title { 'capital project title' }
    description { 'capital project description' }
    justification { 'capital project justification' }
  end

end
