FactoryBot.define do

  factory :organization do
    customer_id { 1 }
    address1 { '100 Main St' }
    city { 'Harrisburg' }
    state { 'PA' }
    zip { '17120' }
    url { 'http://www.example.com' }
    phone { '9999999999' }
    grantor_id { 1 }
    organization_type { OrganizationType.find_by(:class_name => 'TransitOperator') rescue Rails.logger.info "ERROR: No seed data." }
    sequence(:name) { |n| "Org #{n}" }
    short_name {name}
    legal_name {name}
    license_holder { true }
  end

end
