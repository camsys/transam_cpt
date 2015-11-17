FactoryGirl.define do

  factory :funding_source do
    name 'Test Funding Source'
    description 'Test Funding Source Description'
    funding_source_type_id 1
    federal_match_required 50.0
    state_match_required 30.0
    local_match_required 20.0
  end

end
