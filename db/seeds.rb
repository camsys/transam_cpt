#encoding: utf-8

# determine if we are using postgres or mysql
is_mysql = (ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'mysql2')

#------------------------------------------------------------------------------
#
# Lookup Tables
#
# These are lookup tables for the Capital Planning Tool
#
#------------------------------------------------------------------------------

capital_project_status_types = [
  {:active => 1, :name => 'Status 1',       :description => 'Status 1'},
  {:active => 1, :name => 'Status 2',       :description => 'Status 2'},
  {:active => 1, :name => 'Status 3',       :description => 'Status 3'}
]

capital_project_types = [
  {:active => 1, :name => 'SOGR Replacement Project',     :code => "RP",  :description => 'SOGR Replacement Project'},
  {:active => 1, :name => 'SOGR Rehabilitation Project',  :code => "RH",  :description => 'SOGR Rehabilitation Project'},
  {:active => 1, :name => 'Enhancement Project',          :code => "EP",  :description => 'Enhancement Project'}
]

milestone_types = [
  {:active => 1, :name => 'Out for Bid',          :description => 'Out for Bid'},
  {:active => 1, :name => 'Contract Awarded',     :description => 'Contract Awarded'},
  {:active => 1, :name => 'Notice to Proceed',    :description => 'Notice to Proceed'},
  {:active => 1, :name => 'Delivery Started',     :description => 'Delivery Started'},
  {:active => 1, :name => 'Delivery Completed',   :description => 'Delivery Completed'},
  {:active => 1, :name => 'Contract Completed',   :description => 'Contract Completed'}
]

reports = [
  {
    :active => 1, 
    :belongs_to => 'report_type', 
    :type => "Capital Needs Report",     
    :name => 'Capital Needs Forecast',  
    :class_name => "CapitalNeedsForecast",
    :view_name => "generic_chart",  
    :show_in_nav => 1, 
    :show_in_dashboard => 0, 
    :description => 'Displays a chart showing the funding forcast by fiscal year.',  
    :chart_type => 'column',     
    :chart_options => "{is3D : true, isStacked : true, hAxis: {title: 'Fiscal Year'}, vAxis: {title: '$'}}"
    }
]

lookup_tables = %w{capital_project_status_types milestone_types capital_project_types }
merge_tables = %w{reports }

puts ">>> Loading CPT Lookup Tables <<<<"
lookup_tables.each do |table_name|
  puts "  Processing #{table_name}"
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

puts ">>> Loading CPT Merge Tables <<<<"
lookup_tables.each do |table_name|
  puts "  Processing #{table_name}"
  data = eval(table_name)
  klass = table_name.classify.constantize
  data.each do |row|
    x = klass.new(row)
    x.save!
  end
end

