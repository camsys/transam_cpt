# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  sequence :asset_tag do |n|
    "ABS_TAG#{n}"
  end

  trait :basic_asset_attributes do
    association :organization, :factory => :organization
    asset_tag
    purchase_date { 1.year.ago }
    policy_replacement_year { 1.year.from_now.year }
    scheduled_rehabilitation_year { 1.year.from_now.year }
    manufacture_year { 14.years.ago }
    fta_funding_type_id 1
    created_by_id 1
  end

  factory :buslike_asset, :class => :asset do # An untyped asset which looks like a bus
    basic_asset_attributes
    # TODO This probably needs to be a better selection
    asset_type {AssetType.first}
    asset_subtype {AssetSubtype.first}
    purchase_cost 2000.0
    expected_useful_life 10
    reported_condition_rating 2.0
  end

  factory :buslike_asset2, :class => :asset do # An untyped asset which looks like a bus
    basic_asset_attributes
    # TODO This probably needs to be a better selection
    asset_type {AssetType.first}
    asset_subtype {AssetSubtype.first}
    purchase_cost 2000.0
    expected_useful_life 15
    reported_condition_rating 3.0

    purchase_date { 2.years.ago }
    policy_replacement_year { 2.years.from_now.year }
    scheduled_rehabilitation_year { 12.years.from_now.year }
    manufacture_year { 14.years.ago }
  end

end
