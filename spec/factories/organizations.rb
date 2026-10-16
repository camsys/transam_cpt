FactoryBot.define do

  trait :basic_organization_attributes do
    customer_id { 1 }
    address1 { '100 Main St' }
    city { 'Harrisburg' }
    state { 'PA' }
    zip { '17120' }
    url { 'http://www.example.com' }
    phone { '9999999999' }
    license_holder { true }
  end

  factory :organization do
    basic_organization_attributes
    sequence(:name) { |n| "Org #{n}" }
    short_name {name}
    legal_name {name}
    organization_type { OrganizationType.find_by(:class_name => 'TransitOperator') rescue Rails.logger.info "ERROR: No seed data." }
  end

  factory :grantor do
    basic_organization_attributes
    sequence(:name) { |n| "Grantor Org #{n}" }
    short_name {name}
    legal_name {name}
    organization_type { OrganizationType.find_by(:class_name => 'Grantor') rescue Rails.logger.info "ERROR: No seed data." }
    fta_agency_type_id {2}
    fta_service_area_type_id {2}
    ntd_reporting_start_month {7}
  end

end
