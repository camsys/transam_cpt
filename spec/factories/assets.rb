# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do

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
    fta_funding_type_id { 1 }
    created_by_id { 1 }
  end

  factory :buslike_asset, :class => :asset do # An untyped asset which looks like a bus
    basic_asset_attributes
    association :asset_type
    association :asset_subtype
    purchase_cost { 2000.0 }
    expected_useful_life { 10 }
    reported_condition_rating { 2.0 }
  end

  factory :buslike_asset2, :class => :asset do # An untyped asset which looks like a bus
    basic_asset_attributes
    association :asset_type
    association :asset_subtype
    purchase_cost { 2000.0 }
    expected_useful_life { 15 }
    reported_condition_rating { 3.0 }

    purchase_date { 2.years.ago }
    policy_replacement_year { 2.years.from_now.year }
    scheduled_rehabilitation_year { 12.years.from_now.year }
    manufacture_year { 14.years.ago }
  end

  factory :transam_asset do
    asset_tag
    purchase_cost { 2000.0 }
    purchase_date { 1.year.ago }
    in_service_date { 1.year.ago }
    purchased_new { false }
    association :organization, :factory => :organization
  end

  factory :transit_asset, :class => :transit_asset  do
    asset_tag
    purchase_cost { 2000.0 }
    purchase_date { 1.year.ago }
    in_service_date { 1.year.ago }
    purchased_new { false }
    association :organization, :factory => :organization
    fta_asset_category { FtaAssetCategory.first }
    fta_asset_class { FtaAssetClass.find_by(code: "bus") }
    fta_type_id { 10 }
    fta_type_type { "FtaVehicleType" }

  end

  factory :service_vehicle, :class => :service_vehicle do
    asset_tag
    purchase_cost { 2000.0 }
    purchase_date { 1.year.ago }
    in_service_date { 1.year.ago }
    purchased_new { false }
    association :organization, :factory => :organization
    fta_asset_category { FtaAssetCategory.find_by(name: "Equipment") }
    fta_asset_class { FtaAssetClass.find_by(code: "service_vehicle") }
    fta_type_id { 1 }
    fta_type_type { "FtaSupportVehicleType" }
    manufacture_year { 1.year.ago }
    serial_number { "TESTSERNUM1234567" }
    manufacturer_id { 1 }
    manufacturer_model_id { 1 }
    fuel_type_id { 18 }
    vehicle_length { 10 }
    vehicle_length_unit { 'feet' }
    seating_capacity { 5 }
    ada_accessible { true }
  end

  factory :buslike_asset_basic_org, :class => :asset do # An untyped asset which looks like a bus
    basic_asset_attributes
    association :asset_type
    association :asset_subtype
    purchase_cost { 2000.0 }
    expected_useful_life { 120 }
    reported_condition_rating { 2.0 }
    association :organization, :factory => :organization
  end

  factory :equipment_asset, :class => :equipment do # An untyped asset which looks like a bus
    basic_asset_attributes
    association :asset_type, :factory => :equipment_type
    association :asset_subtype, :factory => :equipment_subtype
    description { 'equipment test' }
    purchase_cost { 2000.0 }
    quantity { 1 }
    quantity_units { 'piece' }
    expected_useful_life { 120 }
    reported_condition_rating { 2.0 }
  end

  factory :equipment_asset_basic_org, :class => :equipment do # An untyped asset which looks like a bus
    basic_asset_attributes
    association :asset_type, :factory => :equipment_type
    association :asset_subtype, :factory => :equipment_subtype
    description { 'equipment test' }
    purchase_cost { 2000.0 }
    quantity { 1 }
    quantity_units { 'piece' }
    expected_useful_life { 120 }
    reported_condition_rating { 2.0 }
    association :organization, :factory => :organization
  end

end
