#encoding: utf-8

# determine if we are using postgres or mysql
is_mysql = (ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'mysql2')
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
]

capital_project_types = [
  {:active => 1, :name => 'Replacement',    :code => "R",  :description => 'The capital project is aimed at replacing existing assets.'},
  {:active => 1, :name => 'Expansion',      :code => "E",  :description => 'The capital project is aimed at enhancing the service fleet or operations.'},
  {:active => 1, :name => 'Improvement',    :code => "I",  :description => 'The capital project is aimed at improving existing services.'},
  {:active => 1, :name => 'Demonstration',  :code => "D",  :description => 'The capital project is aimed at demonstrating new services.'}
]

milestone_types = [
  {:active => 1, :name => 'Out for Bid',            :is_vehicle_delivery => 0, :description => 'Out for Bid'},
  {:active => 1, :name => 'Contract Awarded',       :is_vehicle_delivery => 0, :description => 'Contract Awarded'},
  {:active => 1, :name => 'Notice to Proceed',      :is_vehicle_delivery => 0, :description => 'Notice to Proceed'},
  {:active => 1, :name => 'First Vehicle Delivered',:is_vehicle_delivery => 1, :description => 'Delivery Started'},
  {:active => 1, :name => 'All Vehicles Delivered', :is_vehicle_delivery => 1, :description => 'Delivery Completed'},
  {:active => 1, :name => 'Contract Completed',     :is_vehicle_delivery => 0, :description => 'Contract Completed'}
]

funding_source_types = [
  {:active => 1, :name => 'Federal',  :description => 'Federal Funding Source'},
  {:active => 1, :name => 'State',    :description => 'State Funding Source'}
]

# Funding Line Item Types
funding_line_item_types = [
  {:active => 1, :name => 'Earmark',        :code => "EM",  :description => 'Funds are earmarked.'},
  {:active => 1, :name => 'Flex Funds',     :code => "FF",  :description => 'Funds are flex funds.'},
  {:active => 1, :name => 'Formula',        :code => "FR",  :description => 'Funds are formular funds.'},
  {:active => 1, :name => 'Discretionary',  :code => "DS",  :description => 'Funds are discretionary.'},
  {:active => 1, :name => 'Other',          :code => "OT",  :description => 'Other.'}
]



replace_tables = %w{ milestone_types capital_project_types funding_source_types funding_line_item_types }
merge_tables = %w{ roles }

replace_tables.each do |table_name|
  puts "  Loading #{table_name}"
  if is_mysql
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name};")
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

reports = [
  {
    :active => 1,
    :belongs_to => 'report_type',
    :type => "Capital Needs Report",
    :name => 'Capital Needs Forecast',
    :class_name => "CapitalNeedsForecast",
    :view_name => "generic_chart",
    :show_in_nav => 1,
    :show_in_dashboard => 1,
    :roles => 'user,manager',
    :description => 'Displays a chart showing the funding forecast by fiscal year.',
    :chart_type => 'column',
    :chart_options => "{is3D : false, isStacked: false, fontSize: 10, hAxis: {title: 'Fiscal Year'}, vAxis: {title: '$'}}"
    },
  {
    :active => 1,
    :belongs_to => 'report_type',
    :type => "Capital Needs Report",
    :name => 'Cash Flow Forecast',
    :class_name => "CashFlowForecast",
    :view_name => "cash_flow_forecast",
    :show_in_nav => 1,
    :show_in_dashboard => 0,
    :roles => 'user,manager',
    :description => 'Displays a chart showing the cash flow forecast for the current organization.',
    :chart_type => "combo",
    :chart_options => "{is3D : false, seriesType: 'bars', series: {3: {type: 'line'}}, fontSize: 10, hAxis: {title: 'Fiscal Year'}, vAxis: {title: '$'}}"
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
