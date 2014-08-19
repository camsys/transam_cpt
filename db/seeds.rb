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
  {:active => 1, :name => 'Unprogrammed', :description => 'The Capital Project has no funds or is only partially funded.'},
  {:active => 1, :name => 'Programmed',   :description => 'The Capital Project has been fully funded by not approved.'},
  {:active => 1, :name => 'Pending',      :description => 'The Capital Project has been fully funded and has been submitted for approval.'},
  {:active => 1, :name => 'Approved',     :description => 'The Capital Project has been approved.'}
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
    :description => 'Displays a chart showing the funding forecast by fiscal year.',
    :chart_type => 'area',
    :chart_options => "{is3D : true, fontSize: 10, colors:['red','blue','green'], hAxis: {title: 'Fiscal Year'}, vAxis: {title: '$'}}"
    },
  {
    :active => 1,
    :belongs_to => 'report_type',
    :type => "Capital Needs Report",
    :name => 'Budget Summary',
    :class_name => "BudgetSummary",
    :view_name => "budget_summary",
    :show_in_nav => 1,
    :show_in_dashboard => 0,
    :description => 'Displays a chart showing the budget summary for the current organization.',
    :chart_type => "",
    :chart_options => ""
    }
]

funding_source_types = [
  {:active => 1, :name => 'Federal',  :description => 'Federal Funding Source'},
  {:active => 1, :name => 'State',    :description => 'State Funding Source'}
]

funding_sources = [
  {
    :active => 1,
    :name => '5307 FTA Capital Improvements: ICR',
    :description => "The Urbanized Area Formula Funding Program (5307). Provides transit capital and operating assistance in urbanized areas and for transportation related planning.  Eligible activities include planning, engineering design and evaluation of transit projects and other technical transportation-related studies; capital investments in bus and bus-related activities such as replacement of buses, overhaul of buses, rebuilding of buses, crime prevention and security equipment and construction of maintenance and passenger shelters.",
    :funding_source_type_id => 1,
    :external_id => "41",
    :state_administered_federal_fund => 1,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 0,
    :rural_providers => 0,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 20.0,
    :federal_match_required => 80.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '5309 FTA Capital Discretionary: ICR',
    :description => "Bus and Bus Facilities (5309). The transit capital investment program. The New Starts program provides funds for construction of new fixed guideway systems or extensions to existing fixed guideway systems. The Small Starts program provides funds to capital projects that either (a) meet the definition of a fixed guideway for at least 50 percent of the project length in the peak period or (b) are corridor-based bus projects with 10 minute peak/15 minute off-peak headways or better while operating at least 14 hours per weekday.",
    :funding_source_type_id => 1,
    :external_id => "42",
    :state_administered_federal_fund => 1,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 1,
    :inter_city_bus_providers => 1,
    :inter_city_rail_providers => 1,
    :state_match_required => 20.0,
    :federal_match_required => 80.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '5310 FTA Capital Improvements: Grants',
    :description => "Transportation for Elderly Persons and Persons with Disabilities (5310). Federal Elderly and Persons with Disabilities program to be used for related preventative maintenance, contracting for service, provision of a fixed-route paratransit service, leasing of equipment or facilities, safety equipment and facilities, facilities that incorporate community services (such as day care or health care), and transit enhancements.",
    :funding_source_type_id => 1,
    :external_id => "43",
    :state_administered_federal_fund => 1,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 0,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 1,
    :inter_city_bus_providers => 1,
    :inter_city_rail_providers => 1,
    :state_match_required => 20.0,
    :federal_match_required => 80.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '5311 ARRA',
    :description => "Rural Transit Assistance Program (5311(b)(3)). Aims to assist in the design and implementation of training and technical assistance projects and other support services tailored to meet the needs of transit operators in nonurbanized areas.",
    :funding_source_type_id => 1,
    :external_id => "44",
    :state_administered_federal_fund => 1,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 0,
    :rural_providers => 1,
    :urban_providers => 0,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 0.0,
    :federal_match_required => 100.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '5316 Capital Improvements: WAW, JARC',
    :description => "Job Access and Reverse Commute Program (5316). Aims to address the unique transportation challenges faced by welfare recipients and low-income persons seeking to obtain and maintain employment.",
    :funding_source_type_id => 1,
    :external_id => "48",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 0,
    :rural_providers => 0,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 1,
    :inter_city_rail_providers => 0,
    :state_match_required => 20.0,
    :federal_match_required => 80.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '5317 Capital Improvements: New Freedom',
    :description => "New Freedom Program. Aims to provide additional tools to overcome existing barriers facing Americans with disabilities seeking integration into the work force and full participation in society.",
    :funding_source_type_id => 1,
    :external_id => "49",
    :state_administered_federal_fund => 1,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 1,
    :inter_city_bus_providers => 1,
    :inter_city_rail_providers => 1,
    :state_match_required => 20.0,
    :federal_match_required => 80.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  # {
  #   :active => 1,
  #   :name => 'Flex',
  #   :description => "Used to track funding TBD or not tracked in CPT",
  #   :funding_source_type_id => 1,
  #   :external_id => "???",
  #   :state_administered_federal_fund => 1,
  #   :bond_fund => 0,
  #   :formula_fund => 0,
  #   :non_committed_fund => 0,
  #   :contracted_fund => 1,
  #   :discretionary_fund => 0,
  #   :created_by_id => sys_user_id,
  #   :updated_by_id => sys_user_id,
  #   :default_amount => 50000000
  #   },
  {
    :active => 1,
    :name => '1513',
    :description => "Operating Funds",
    :funding_source_type_id => 2,
    :external_id => "46",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 1,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 100.0,
    :federal_match_required => 0.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1514 Bond',
    :description => "Asset Improvement Program; Provide financial assistance for improvement replacement or expansion of capital projects.",
    :funding_source_type_id => 2,
    :external_id => "11",
    :state_administered_federal_fund => 0,
    :bond_fund => 1,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 16.67,
    :federal_match_required => 80.0,
    :local_match_required => 3.33,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1514 Discretionary',
    :description => "Asset Improvement Program",
    :funding_source_type_id => 2,
    :external_id => "17",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 19.355,
    :federal_match_required => 80.0,
    :local_match_required => 0.645,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1516 CTC',
    :description => "Community Transportation Capital Equipment: Funding for the maintenance replacement and/or upgrade of shared-ride services.",
    :funding_source_type_id => 2,
    :external_id => "27",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 1,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 100.0,
    :federal_match_required => 0.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1516 Intercity Bus',
    :description => "Programs of Statewide significance - The department is authorized to provide financial assistance for an efficient and coordinated intercity common carier surface transportation program, consisting of both intercity passenger rail service and intercity bus service transportation, with the intent of sustaining strong intercity connections. All of the following shall apply.",
    :funding_source_type_id => 2,
    :external_id => "74",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 1,
    :inter_city_rail_providers => 0,
    :state_match_required => 100.0,
    :federal_match_required => 0.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1516 Intercity Rail',
    :description => "For intercity bus service operating and capital assistance, financial assistance shall require a local match by local or private cash funding in an amount equal to at least 100% of the amount of the financial assistance being provided.",
    :funding_source_type_id => 2,
    :external_id => "75",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 1,
    :state_match_required => 100.0,
    :federal_match_required => 0.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1516 JARC',
    :description => "To provide state matching funds for the Federal Job Access and Reverse Commute Program (JARC). The JARC goals are to improve access to transportation services to employment and employment-related activities for low-income individuals and welfare recipients and to transport residents of urbanized areas and non-urbanized areas to suburban employment opportunities.",
    :funding_source_type_id => 2,
    :external_id => "40",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 100.0,
    :federal_match_required => 0.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1516 New Freedom',
    :description => "State matching funds for capital equipment for transit agencies to provide service for individuals with disabilities.",
    :funding_source_type_id => 2,
    :external_id => "81",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 100.0,
    :federal_match_required => 0.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1516 PwD',
    :description => "Persons with Disabilities: reduced fare transportation program for shared-ride service for persons who have a disability; are 18-64 years of age; and live in a county participating in the PwD program or need transportation to or from a PwD project area that is not currently served by public fixed route bus transportation and ADA complementary paratransit services.",
    :funding_source_type_id => 2,
    :external_id => "30",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 1,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 100.0,
    :federal_match_required => 0.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1516 Technical Assistance',
    :description => "State matching funds for technical assistance projects.",
    :funding_source_type_id => 2,
    :external_id => "114",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 1,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 100.0,
    :federal_match_required => 0.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => '1517',
    :description => "Financial assistance for capital improvement (100%).",
    :funding_source_type_id => 2,
    :external_id => "13",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 1,
    :non_committed_fund => 0,
    :contracted_fund => 1,
    :discretionary_fund => 0,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 100.0,
    :federal_match_required => 0.0,
    :local_match_required => 0.0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => 'Act 3 ASG',
    :description => "Financial assistance for capital asset maintenance.",
    :funding_source_type_id => 2,
    :external_id => "18",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 1,
    :contracted_fund => 0,
    :discretionary_fund => 0,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 16.67,
    :federal_match_required => 80.0,
    :local_match_required => 3.33,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => 'Act 3 BSG',
    :description => "Financial assistance for operating and asset maintenance.",
    :funding_source_type_id => 2,
    :external_id => "22",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 1,
    :contracted_fund => 0,
    :discretionary_fund => 0,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 16.67,
    :federal_match_required => 80.0,
    :local_match_required => 3.33,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => 'Disposition/Settlement Revenue',
    :description => "Fund used by BPT and grantees to allow for disposition of asset funds and funds received from settlements to be documented and tracked within the dotGrants system.",
    :funding_source_type_id => 2,
    :external_id => "45",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 1,
    :contracted_fund => 0,
    :discretionary_fund => 0,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 0,
    :federal_match_required => 0,
    :local_match_required => 0,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    },
  {
    :active => 1,
    :name => 'PTAF',
    :description => "Financial assistance for capital asset maintenance.",
    :funding_source_type_id => 2,
    :external_id => "25",
    :state_administered_federal_fund => 0,
    :bond_fund => 0,
    :formula_fund => 0,
    :non_committed_fund => 1,
    :contracted_fund => 0,
    :discretionary_fund => 0,
    :rural_providers => 1,
    :urban_providers => 1,
    :shared_ride_providers => 0,
    :inter_city_bus_providers => 0,
    :inter_city_rail_providers => 0,
    :state_match_required => 16.67,
    :federal_match_required => 80.0,
    :local_match_required => 3.33,
    :created_by_id => sys_user_id,
    :updated_by_id => sys_user_id
    }
]

# Funding Line Item Types
funding_line_item_types = [
  {:active => 1, :name => 'Earmark',        :code => "EM",  :description => 'Funds are earmarked.'},
  {:active => 1, :name => 'Flex Funds',     :code => "FF",  :description => 'Funds are flex funds.'},
  {:active => 1, :name => 'Formula',        :code => "FR",  :description => 'Funds are formular funds.'},
  {:active => 1, :name => 'Discretionary',  :code => "DS",  :description => 'Funds are discretionary.'},
  {:active => 1, :name => 'Other',          :code => "OT",  :description => 'Other.'}
]

lookup_tables = %w{ capital_project_status_types milestone_types capital_project_types funding_source_types funding_line_item_types }
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
if is_mysql
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name};")
else
  ActiveRecord::Base.connection.execute("TRUNCATE #{table_name} RESTART IDENTITY;")
end
data = eval(table_name)
data.each do |row|
  x = FundingSource.new(row.except(:default_amount))
  x.save!
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

