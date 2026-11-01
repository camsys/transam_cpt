FactoryBot.define do
  trait :basic_scenario_attributes do
    association :organization, :factory => :organization
    association :reviewer_organization, :factory => :grantor
    sequence(:name) { |n| "Test Scenario #{n}" }
  end

  factory :scenario do
    basic_scenario_attributes
  end

  factory :unconstrained_scenario, :class => :scenario do
    basic_scenario_attributes
    state { "unconstrained_plan" }
  end

  factory :constrained_scenario, :class => :scenario do
    basic_scenario_attributes
    state { "constrained_plan" }
  end

  factory :submitted_constrained_scenario, :class => :scenario do
    basic_scenario_attributes
    state { "submitted_constrained_plan" }
  end

  factory :submitted_unconstrained_scenario, :class => :scenario do
    basic_scenario_attributes
    state { "submitted_unconstrained_plan" }
  end

  factory :final_draft_scenario, :class => :scenario do
    basic_scenario_attributes
    state { "final_draft" }
  end

  factory :awaiting_approval_scenario, :class => :scenario do
    basic_scenario_attributes
    state { "awaiting_final_approval" }
  end

  factory :approved_scenario, :class => :scenario do
    basic_scenario_attributes
    state { "approved" }
  end

  factory :cancelled_scenario, :class => :scenario do
    basic_scenario_attributes
    state { "cancelled" }
  end
end