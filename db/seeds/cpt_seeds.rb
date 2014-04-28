#encoding: utf-8

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

milestone_types = [
  {:active => 1, :name => 'Out for Bid',          :description => 'Out for Bid'},
  {:active => 1, :name => 'Contract Awarded',     :description => 'Contract Awarded'},
  {:active => 1, :name => 'Notice to Proceed',    :description => 'Notice to Proceed'},
  {:active => 1, :name => 'Delivery Started',     :description => 'Delivery Started'},
  {:active => 1, :name => 'Delivery Completed',   :description => 'Delivery Completed'},
  {:active => 1, :name => 'Contract Completed',   :description => 'Contract Completed'}
]

team_scope_categories = [
  {:active => 1, :name => 'Capital'},
  {:active => 1, :name => 'Operating'},
  {:active => 1, :name => 'Planning'},
  {:active => 1, :name => 'Review'},
  {:active => 1, :name => 'Safety & Security'},
  {:active => 1, :name => 'Special Categories'},
  {:active => 1, :name => 'Non-add Codes'}
]

team_scope_codes = [
  {:active => 1, :team_scope_category_id => 1, :code => '111-00', :name => 'Bus Rolling Stock'},
  {:active => 1, :team_scope_category_id => 1, :code => '112-00', :name => 'Bus Transitways/Lines'},
  {:active => 1, :team_scope_category_id => 1, :code => '113-00', :name => 'Bus Station Stops & Terminals'},
  {:active => 1, :team_scope_category_id => 1, :code => '114-00', :name => 'Bus Support Equip/Facilities'},
  {:active => 1, :team_scope_category_id => 1, :code => '115-00', :name => 'Bus Electrification/Power Dist.'},
  {:active => 1, :team_scope_category_id => 1, :code => '116-00', :name => 'Bus Signal & Communication Equip.'},
  {:active => 1, :team_scope_category_id => 1, :code => '117-00', :name => 'Bus Other Capital Items'},
  {:active => 1, :team_scope_category_id => 1, :code => '119-00', :name => 'Bus Transit Enhancements'},

  {:active => 1, :team_scope_category_id => 1, :code => '121-00', :name => 'Rail Rolling Stock'},
  {:active => 1, :team_scope_category_id => 1, :code => '122-00', :name => 'Rail Transitways/Lines'},
  {:active => 1, :team_scope_category_id => 1, :code => '123-00', :name => 'Rail Station Stops & Terminals'},
  {:active => 1, :team_scope_category_id => 1, :code => '124-00', :name => 'Rail Support Equip/Facilities'},
  {:active => 1, :team_scope_category_id => 1, :code => '125-00', :name => 'Rail Electrification/Power Dist.'},
  {:active => 1, :team_scope_category_id => 1, :code => '126-00', :name => 'Rail Signal & Communication Equip.'},
  {:active => 1, :team_scope_category_id => 1, :code => '127-00', :name => 'Rail Other Capital Items'},
  {:active => 1, :team_scope_category_id => 1, :code => '129-00', :name => 'Rail Transit Enhancements'},

  {:active => 1, :team_scope_category_id => 1, :code => '131-00', :name => 'New Start Rolling Stock'},
  {:active => 1, :team_scope_category_id => 1, :code => '132-00', :name => 'New Start Transitways/Lines'},
  {:active => 1, :team_scope_category_id => 1, :code => '133-00', :name => 'New Start Stops & Terminals'},
  {:active => 1, :team_scope_category_id => 1, :code => '134-00', :name => 'New Start Support Equip/Facilities'},
  {:active => 1, :team_scope_category_id => 1, :code => '135-00', :name => 'New Start Electrification/Power Dist.'},
  {:active => 1, :team_scope_category_id => 1, :code => '136-00', :name => 'New Start Signal & Communication Equip.'},
  {:active => 1, :team_scope_category_id => 1, :code => '137-00', :name => 'New Start Other Capital Items'},
  {:active => 1, :team_scope_category_id => 1, :code => '139-00', :name => 'New Start Transit Enhancements'},

  {:active => 1, :team_scope_category_id => 2, :code => '300-00', :name => 'Operating Assistance'},

  {:active => 1, :team_scope_category_id => 3, :code => '441-00', :name => 'State Planning and Research', :instructions => 'Use 42.2X.XX ALIs'},
  {:active => 1, :team_scope_category_id => 3, :code => '441-10', :name => 'University Research', :instructions => 'Use 70.XX.XX ALIs'},
  {:active => 1, :team_scope_category_id => 3, :code => '441-20', :name => 'Human Resources', :instructions => 'Use 55.XX.XX ALIs'},
  {:active => 1, :team_scope_category_id => 3, :code => '441-30', :name => 'Training Fellowship', :instructions => 'Use 50.XX.XX ALIs'},
  {:active => 1, :team_scope_category_id => 3, :code => '441-60', :name => 'Reseasrch & Development', :instructions => 'Use 55.XX.XX ALIs'},
  {:active => 1, :team_scope_category_id => 3, :code => '441-80', :name => 'Meteropolitain Planning', :instructions => 'Use 42.2X.XX ALIs'},
  {:active => 1, :team_scope_category_id => 3, :code => '442-00', :name => 'Meteropolitain Planning'},
  {:active => 1, :team_scope_category_id => 3, :code => '443-00', :name => 'Consolidated Planning Grants'},

  {:active => 1, :team_scope_category_id => 4, :code => '510-00', :name => 'Oversight Reviews', :instructions => 'Used only by headquarters.'},

  {:active => 1, :team_scope_category_id => 5, :code => '571-00', :name => 'Safety', :instructions => 'Used only for Section 40 Seccurity Drill grants.'},
  {:active => 1, :team_scope_category_id => 5, :code => '572-00', :name => 'Security', :instructions => 'Used only for Section 40 Seccurity Drill grants.'},

  {:active => 1, :team_scope_category_id => 6, :code => '600-00', :name => 'Other Program Costs', :instructions => 'Option: Combine Scopes 300, 610, 620 & 630 into a single scope code.'},
  {:active => 1, :team_scope_category_id => 6, :code => '610-00', :name => 'State Administration', :instructions => 'Use ALI Code 11.80.00'},
  {:active => 1, :team_scope_category_id => 6, :code => '620-00', :name => 'Project Administration', :instructions => 'Use ALI Code 11.79.00'},
  {:active => 1, :team_scope_category_id => 6, :code => '630-00', :name => 'Program Reserve', :instructions => 'Use ALI Code 11.73.00'},
  {:active => 1, :team_scope_category_id => 6, :code => '634-00', :name => 'Intercity Bus Transportation', :instructions => 'Use Capital, Operating, or Plnng ALIs'},
  {:active => 1, :team_scope_category_id => 6, :code => '635-00', :name => 'RTAP', :instructions => 'Use 43.5X.XX ALIs'},

  {:active => 1, :team_scope_category_id => 7, :code => '993-00', :name => 'Fleet Management'},
  {:active => 1, :team_scope_category_id => 7, :code => '994-00', :name => 'Electronic Fare'},
  {:active => 1, :team_scope_category_id => 7, :code => '995-00', :name => 'Traveler Information'},
  {:active => 1, :team_scope_category_id => 7, :code => '996-00', :name => 'ADA/CAA Increased Federal Share'},
  {:active => 1, :team_scope_category_id => 7, :code => '999-00', :name => 'Contingency Projects'}

]

team_categories = [
  {:active => 1, :team_scope_code_id => 1, :code => '11', :name => 'Engineering & Design'},
  {:active => 1, :team_scope_code_id => 1, :code => '12', :name => 'Purchase/Replacement'},
  {:active => 1, :team_scope_code_id => 1, :code => '13', :name => 'Purchase/Expansion'},
  {:active => 1, :team_scope_code_id => 1, :code => '14', :name => 'Rehabilitation/Rebuild'},
  {:active => 1, :team_scope_code_id => 1, :code => '15', :name => 'Mid Life Rebuild (Rail)'},
  {:active => 1, :team_scope_code_id => 1, :code => '16', :name => 'Lease/Replacement'},
  {:active => 1, :team_scope_code_id => 1, :code => '17', :name => 'Vehicle Overhaul'},
  {:active => 1, :team_scope_code_id => 1, :code => '18', :name => 'Lease/Expansion'},

  {:active => 1, :team_scope_code_id => 2, :code => '21', :name => 'Engineering & Design'},
  {:active => 1, :team_scope_code_id => 2, :code => '22', :name => 'Aquisition'},
  {:active => 1, :team_scope_code_id => 2, :code => '23', :name => 'Construction'},
  {:active => 1, :team_scope_code_id => 2, :code => '24', :name => 'Rehab/Renovation'},
  {:active => 1, :team_scope_code_id => 2, :code => '26', :name => 'Lease'},

  {:active => 1, :team_scope_code_id => 3, :code => '31', :name => 'Engineering & Design'},
  {:active => 1, :team_scope_code_id => 3, :code => '32', :name => 'Aquisition'},
  {:active => 1, :team_scope_code_id => 3, :code => '33', :name => 'Construction'},
  {:active => 1, :team_scope_code_id => 3, :code => '34', :name => 'Rehab/Renovation'},
  {:active => 1, :team_scope_code_id => 3, :code => '36', :name => 'Lease'},

  {:active => 1, :team_scope_code_id => 4, :code => '41', :name => 'Engineering & Design'},
  {:active => 1, :team_scope_code_id => 4, :code => '42', :name => 'Aquisition'},
  {:active => 1, :team_scope_code_id => 4, :code => '43', :name => 'Construction'},
  {:active => 1, :team_scope_code_id => 4, :code => '44', :name => 'Rehab/Renovation'},
  {:active => 1, :team_scope_code_id => 4, :code => '46', :name => 'Lease'},

  {:active => 1, :team_scope_code_id => 5, :code => '51', :name => 'Engineering & Design'},
  {:active => 1, :team_scope_code_id => 5, :code => '52', :name => 'Aquisition'},
  {:active => 1, :team_scope_code_id => 5, :code => '53', :name => 'Construction'},
  {:active => 1, :team_scope_code_id => 5, :code => '54', :name => 'Rehab/Renovation'},
  {:active => 1, :team_scope_code_id => 5, :code => '56', :name => 'Lease'},

  {:active => 1, :team_scope_code_id => 6, :code => '61', :name => 'Engineering & Design'},
  {:active => 1, :team_scope_code_id => 6, :code => '62', :name => 'Aquisition'},
  {:active => 1, :team_scope_code_id => 6, :code => '63', :name => 'Construction'},
  {:active => 1, :team_scope_code_id => 6, :code => '64', :name => 'Rehab/Renovation'},
  {:active => 1, :team_scope_code_id => 6, :code => '66', :name => 'Lease'}

]

lookup_tables = %w{capital_project_status_types milestone_types team_scope_categories team_scope_codes team_categories }

puts ">>> Loading CPT Lookup Tables <<<<"
lookup_tables.each do |table_name|
  puts "  Processing #{table_name}"
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name}")
  data = eval(table_name)
  klass = table_name.classify.constantize
  data.each do |row|
    x = klass.new(row)
    x.save!
  end
end

