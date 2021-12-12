FactoryBot.define do

  trait :basic_policy_attributes do
    interest_rate { "0.05" }
    service_life_calculation_type_id { 1 }
    cost_calculation_type_id { 1 }
    condition_estimation_type_id { 1 }
    condition_threshold { 2.5 }
    name { 'TestPolicy' }
    description { 'Test Policy' }
    year { Date.today.year }
    current { true }
    active { true }
  end

  factory :policy do
    basic_policy_attributes
    association :organization, :factory => :organization
  end

  factory :parent_policy, :class => :policy do
    basic_policy_attributes
    name { 'TestParentPolicy' }
    description { 'Test Parent Policy' }
    association :organization, :factory => :organization

    transient do
      has_fuel_type { true }
    end

    transient do
      type { 0 }
    end

    transient do
      subtype { 0 }
    end

    transient do
      replacement_code { 'XX.XX.XX' }
    end

    transient do
      rehab_code { 'XX.XX.XX' }
    end

    trait :fuel_type do
      has_fuel_type { true }
    end

    after(:create) do |policy, evaluator|
      create(:policy_transam_asset_type_rule, policy: policy, asset_type_id: evaluator.type)
      if evaluator.has_fuel_type
        create(:policy_transam_asset_subtype_rule, :fuel_type, policy: policy, asset_subtype_id: evaluator.subtype, purchase_replacement_code: evaluator.replacement_code, rehabilitation_code: evaluator.rehab_code)
      else
        create(:policy_transam_asset_subtype_rule, policy: policy, asset_subtype_id: evaluator.subtype, purchase_replacement_code: evaluator.replacement_code, rehabilitation_code: evaluator.rehab_code)
      end
    end
  end

end