#encoding: utf-8

# determine if we are using postgres or mysql
is_mysql = (ActiveRecord::Base.configurations[Rails.env]['adapter'].include? 'mysql2')
is_sqlite =  (ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'sqlite3')
sys_user_id = 1

puts "======= Processing TransAM CPT Lookup Tables  ======="

#------------------------------------------------------------------------------
#
# Lookup Tables
#
# These are lookup tables for the Capital Planning Tool
#
#------------------------------------------------------------------------------

# Add any gem-specific roles here
roles = [
    {name: 'approver_one', weight: 11, role_parent_id: Role.find_by(name: 'manager').id, :show_in_user_mgmt => true, privilege: true, label: 'Approver 1'},
    {name: 'approver_two', weight: 12, role_parent_id: Role.find_by(name: 'manager').id, :show_in_user_mgmt => true, privilege: true, label: 'Approver 2'},
    {name: 'approver_three', weight: 13, role_parent_id: Role.find_by(name: 'manager').id, :show_in_user_mgmt => true, privilege: true, label: 'Approver 3'},
    {name: 'approver_four', weight: 14, role_parent_id: Role.find_by(name: 'manager').id, :show_in_user_mgmt => true, privilege: true, label: 'Approver 4'},
]

asset_event_types = [
  {:active => 1, :name => 'Replacement status', :class_name => 'ReplacementStatusUpdateEvent', :job_name => 'AssetReplacementStatusUpdateJob', :display_icon_name => 'fa fa-refresh', :description => 'Replacement Status Update'}
]

capital_project_types = [
  {:active => 1, :name => 'Replacement',    :code => "R",  :description => 'The capital project is aimed at replacing existing assets.'},
  {:active => 1, :name => 'Expansion',      :code => "E",  :description => 'The capital project is aimed at enhancing the service fleet or operations.'},
  {:active => 1, :name => 'Improvement',    :code => "I",  :description => 'The capital project is aimed at improving existing services.'},
  {:active => 1, :name => 'Demonstration',  :code => "D",  :description => 'The capital project is aimed at demonstrating new services.'}
]

milestone_types = [
  {:active => 1, :name => 'Out for Bid',            :is_vehicle_delivery => 0, :description => 'Out for Bid'},
  {:active => 1, :name => 'Contract Award',       :is_vehicle_delivery => 0, :description => 'Contract Award'},
  {:active => 1, :name => 'Notice to Proceed',      :is_vehicle_delivery => 0, :description => 'Notice to Proceed'},
  {:active => 1, :name => 'First Vehicle Delivered',:is_vehicle_delivery => 1, :description => 'Delivery Started'},
  {:active => 1, :name => 'All Vehicles Delivered', :is_vehicle_delivery => 1, :description => 'Delivery Completed'},
  {:active => 1, :name => 'Contract Complete',     :is_vehicle_delivery => 0, :description => 'Contract Complete'}
]

replacement_status_types = [
    {:active => 1, :name => 'By Policy', :description => 'Asset will be replaced following tho policy and planner.'},
    {:active => 1, :name => 'Underway', :description => 'Asset is being replaced this fiscal year.'},
    {:active => 1, :name => 'None', :description => 'Asset is not being replaced.'},
    {:active => 1, :name => 'Pinned', :description => 'Asset replacement is pinned and cannot be moved.'}
]

system_config_extensions = [
    {engine_name: 'cpt', class_name: 'CapitalProject', extension_name: 'TransamKeywordSearchable', active: true},
    {engine_name: 'cpt', class_name: 'ActivityLineItem', extension_name: 'TransamKeywordSearchable', active: true},
    {engine_name: 'cpt', class_name: 'TransamAsset', extension_name: 'TransamCapitalPlannable', active: true},
    {engine_name: 'cpt', class_name: 'TransitOperator', extension_name: 'TransamPlanningOrganization', active: true},
    {engine_name: 'cpt', class_name: 'Grantor', extension_name: 'TransamPlanningOrganization', active: true},
    {engine_name: 'cpt', class_name: 'User', extension_name: 'TransamPlanningFilters', active: true}

]

replace_tables = %w{ milestone_types capital_project_types replacement_status_types }
merge_tables = %w{ roles asset_event_types system_config_extensions }

replace_tables.each do |table_name|
  puts "  Loading #{table_name}"
  if is_mysql
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name};")
  elsif is_sqlite
    ActiveRecord::Base.connection.execute("DELETE FROM #{table_name};")
  else
    ActiveRecord::Base.connection.execute("TRUNCATE #{table_name} RESTART IDENTITY;")
  end
  data = eval(table_name)
  klass = table_name.classify.constantize
  data.each do |row|
    x = klass.new(row)
    x.save!
  end
end

merge_tables.each do |table_name|
  puts "  Merging #{table_name}"
  data = eval(table_name)
  klass = table_name.classify.constantize
  data.each do |row|
    x = klass.new(row)
    x.save!
  end
end

query_params = [

]


reports = [
  {
    :active => false,
    :belongs_to => 'report_type',
    :type => "Capital Needs Report",
    :name => 'Capital Needs Forecast',
    :class_name => "CapitalNeedsForecast",
    :view_name => "generic_chart",
    :show_in_nav => 1,
    :show_in_dashboard => 1,
    :roles => 'guest,user,manager',
    :description => 'Displays a chart showing the capital needs forecast by fiscal year.',
    :chart_type => 'column',
    :chart_options => "{is3D : false, isStacked: false, fontSize: 10, hAxis: {title: 'Fiscal Year'}, vAxis: {title: '$'}}",
    :printable => true,
    :exportable => true
    },
  {
    :active => 0,
    :belongs_to => 'report_type',
    :type => "Capital Needs Report",
    :name => 'Cash Flow Forecast',
    :class_name => "CashFlowForecast",
    :view_name => "cash_flow_forecast",
    :show_in_nav => 1,
    :show_in_dashboard => 0,
    :roles => 'guest,user,manager',
    :description => 'Displays a chart showing the cash flow forecast for the current organization.',
    :chart_type => "combo",
    :chart_options => "{is3D : false, seriesType: 'bars', series: {3: {type: 'line'}}, fontSize: 10, hAxis: {title: 'Fiscal Year'}, vAxis: {title: '$'}}"
    },
  {
    :active => 1,
    :belongs_to => 'report_type',
    :type => "Capital Needs Report",
    :name => 'Unconstrained Capital Needs Forecast',
    :class_name => "UnconstrainedCapitalNeedsForecast",
    :view_name => "generic_chart",
    :show_in_nav => 0,
    :show_in_dashboard => 0,
    :roles => 'guest,user,manager',
    :description => 'Displays a chart showing unconstrained capital needs forecast by fiscal year.',
    :chart_type => 'column',
    :chart_options => "{is3D : false, isStacked: false, fontSize: 10, hAxis: {title: 'Fiscal Year'}, vAxis: {title: '$'}}"
  },
  {
    :active => 1,
    :belongs_to => 'report_type',
    :type => "Capital Needs Report",
    :name => 'Unconstrained Capital Projects Report',
    :class_name => "CapitalProjectsReport",
    :view_name => "capital_projects_report",
    :show_in_nav => 1,
    :show_in_dashboard => 1,
    :roles => 'guest,user',
    :description => 'Displays a report showing unconstrained capital projects by fiscal year.',
    :chart_type => '',
    :chart_options => "",
    :printable => true,
    :exportable => true
  }

]

table_name = 'reports'
puts "  Merging #{table_name}"
data = eval(table_name)
data.each do |row|
  x = Report.new(row.except(:belongs_to, :type))
  x.report_type = ReportType.where(:name => row[:type]).first
  x.save!
end
