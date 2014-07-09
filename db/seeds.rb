#encoding: utf-8

# determine if we are using postgres or mysql
is_mysql = (ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'mysql2')
sys_user_id = 1
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
  {:active => 1, :name => 'SOGR Fleet replacement project',     :code => "SRP",  :description => 'SOGR Fleet Replacement Project'},
  {:active => 1, :name => 'SOGR Fleet rebuild project',         :code => "SRH",  :description => 'SOGR Fleet Rehabilitation Project'},
  {:active => 1, :name => 'SOGR Rail mid-life rebuild project', :code => "SMR",  :description => 'SOGR Rail mid-life rebuild project'},
  {:active => 1, :name => 'SOGR Vehicle overhaul project',      :code => "VOH",  :description => 'SOGR Vehicle overhaul project'},
  {:active => 1, :name => 'Fleet expansion project',            :code => "FEX",  :description => 'Fleet expansion project'},
  {:active => 1, :name => 'Facility lease project',             :code => "FLP",  :description => 'Facility lease project'},
  {:active => 1, :name => 'Facility purchase project',          :code => "FLP",  :description => 'Facility purchase project'},
  {:active => 1, :name => 'Facility renovation project',        :code => "FRP",  :description => 'Facility renovation project'},
  {:active => 1, :name => 'Operating assistance project',       :code => "OAP",  :description => 'Operating assistance project'},
  {:active => 1, :name => 'Other captial project',              :code => "OCP",  :description => 'Other captial project'}
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
    :show_in_dashboard => 1, 
    :description => 'Displays a chart showing the funding forcast by fiscal year.',  
    :chart_type => 'column',     
    :chart_options => "{is3D : true, isStacked : true, hAxis: {title: 'Fiscal Year'}, vAxis: {title: '$'}}"
    }
]

funding_source_types = [
  {:active => 1, :name => 'Federal',  :description => 'Federal Funding Source'},
  {:active => 1, :name => 'State',    :description => 'State Funding Source'}  
]

funding_sources = [
  {
    :active => 1, 
    :name => '5307', 
    :description => "The Urbanized Area Formula Funding program for transit capital and operating assistance in urbanized areas and for transportation related planning.  Eligible activities include planning, engineering design and evaluation of transit projects and other technical transportation-related studies; capital investments in bus and bus-related activities such as replacement of buses, overhaul of buses, rebuilding of buses, crime prevention and security equipment and construction of maintenance and passenger shelters.",     
    :funding_source_type_id => 1,  
    :external_id => "41",
    :state_administered_federal_fund => 1,  
    :bond_fund => 0, 
    :formula_fund => 0, 
    :non_committed_fund => 0,  
    :contracted_fund => 1,     
    :discretionary_fund => 0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id,
    :default_amount => 50000000
    },
  {
    :active => 1, 
    :name => '1513', 
    :description => "Operating Funds",     
    :funding_source_type_id => 2,  
    :external_id => "46",
    :state_administered_federal_fund => 1,  
    :bond_fund => 0, 
    :formula_fund => 0, 
    :non_committed_fund => 1,  
    :contracted_fund => 1,     
    :discretionary_fund => 1,
    :state_match_requried => 100.0,
    :federal_match_requried => 0.0,
    :local_match_requried => 0.0,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_rider_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id,
    :default_amount => 10000000
    }
]

# No funding amounts at this time
funding_amounts = [  
]

lookup_tables = %w{ capital_project_status_types milestone_types capital_project_types funding_source_types funding_amounts}
merge_tables = %w{ reports }

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

puts ">>> Loading Funding Sources <<<<"
table_name = 'funding_sources'
puts "  Processing #{table_name}"
start_fy = 2013
end_fy = start_fy + 12
data = eval(table_name)
data.each do |row|
  x = FundingSource.new(row.except(:default_amount))
  x.save!
  (start_fy..end_fy).each do |year|
    funding_amount = x.build.funding_amount({:amount => row[:default_amount]})
    funding_amount.save
  end
end

puts ">>> Loading CPT Merge Tables <<<<"
table_name = 'reports'
puts "  Processing #{table_name}"
data = eval(table_name)
data.each do |row|
  x = Report.new(row.except(:belongs_to, :type))
  x.report_type = ReportType.where(:name => row[:type]).first
  x.save!
end

