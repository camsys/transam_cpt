FactoryBot.define do

  trait :basic_event_traits do
    association :asset, :factory => :equipment_asset
  end

  factory :asset_event do
    basic_event_traits
    asset_event_type_id 1
  end

  factory :disposition_update_event do
    basic_event_traits
    asset_event_type { AssetEventType.find_by(:class_name => 'DispositionUpdateEvent') }
    disposition_type_id 1
    sales_proceeds 25000
    event_date Date.today
  end

end
