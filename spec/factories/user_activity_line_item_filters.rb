FactoryGirl.define do
  factory :user_activity_line_item_filter do
    sequence(:name) {|n| "Test Filter #{n}"}
    description "Test Filter Description"
    sogr_type "All"
    created_by_user_id 1
  end
end
