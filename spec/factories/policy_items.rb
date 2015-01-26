FactoryGirl.define do

  factory :policy_item do
    max_service_life_months 120
    replacement_cost 395500
    pcnt_residual_value 0
    replacement_ali_code '11.XX.XX'
    rehabilitation_ali_code '11.XX.XX'
    active 1
  end
end
