#encoding: utf-8

# determine if we are using postgres or mysql
is_mysql = (ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'mysql2')

table_name = 'team_ali_codes'
puts "  Processing #{table_name}"
if is_mysql
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name};")
else
  ActiveRecord::Base.connection.execute("TRUNCATE #{table_name} RESTART IDENTITY;")
end

# Start to build the Scope/ALI tree

# Set the root nodes, these are top level categories
TeamAliCode.create!(:name => 'Capital',    :code => '1X.XX.XX')

level_1 = [
  {:name => 'Bus',        :code => '11.XX.XX', :parent_code => '1X.XX.XX'},
  {:name => 'Rail',       :code => '12.XX.XX', :parent_code => '1X.XX.XX'},
  {:name => 'New Start',  :code => '14.XX.XX', :parent_code => '1X.XX.XX'}
]
level_1.each do |h|
  node = TeamAliCode.create!(h.except(:parent_code))
  parent = TeamAliCode.find_by_code(h[:parent_code])
  node.move_to_child_of(parent)
end

# Level 2 for Bus and Fixed Guideways
level_2 = [
  {:name => 'Revenue Rolling Stock',            :cat_code => 'XX.1X.XX'},
  {:name => 'Transitway Lines',                 :cat_code => 'XX.2X.XX'},
  {:name => 'Station Stops/Terminals',          :cat_code => 'XX.3X.XX'},
  {:name => 'Support Facilities and Equipment', :cat_code => 'XX.4X.XX'},
  {:name => 'Electrification Power Dist.',      :cat_code => 'XX.5X.XX'},
  {:name => 'Signal & Communication',           :cat_code => 'XX.6X.XX'},
  {:name => 'Other Capital Program Items.',     :cat_code => 'XX.7X.XX'},
  {:name => 'State or Program Administration',  :cat_code => 'XX.80.00'},
  {:name => 'Transit Enhancements',             :cat_code => 'XX.9X.XX'}
]
# Build the second level for each of the bus and fixed guideway nodes
%w{11.XX.XX 12.XX.XX}.each do |parent_code|
  parent = TeamAliCode.find_by_code(parent_code)
  level_2.each do |h|
    pc = parent_code.split('.')[0]
    tc = h[:cat_code].split('.')[1]
    ac = h[:cat_code].split('.')[2]
    code = "#{pc}.#{tc}.#{ac}"
    node = TeamAliCode.create!(:name => h[:name], :code => code)
    node.move_to_child_of(parent)
  end
end

# Third level for rolling stock only
level_3_rrs = [
  {:name => 'Engineering & Design',     :cat_code => 'XX.11.XX'},
  {:name => 'Purchase - Replacement',   :cat_code => 'XX.12.XX'},
  {:name => 'Purchase - Expansion',     :cat_code => 'XX.13.XX'},
  {:name => 'Rehabilitation/Rebuild',   :cat_code => 'XX.14.XX'},
  {:name => 'Mid Life Rebuild (Rail)',  :cat_code => 'XX.15.XX'},
  {:name => 'Lease - Replacement',      :cat_code => 'XX.16.XX'},
  {:name => 'Lease - Expansion',        :cat_code => 'XX.18.XX'},
  {:name => 'Vehicle Overhaul',         :cat_code => 'XX.17.00'}
]
# Build the third level for each of the bus and fixed guideway nodes
%w{11.1X.XX 12.1X.XX}.each do |parent_code|
  parent = TeamAliCode.find_by_code(parent_code)
  level_3_rrs.each do |h|
    pc = parent_code.split('.')[0]
    tc = h[:cat_code].split('.')[1]
    ac = h[:cat_code].split('.')[2]
    code = "#{pc}.#{tc}.#{ac}"
    node = TeamAliCode.create!(:name => h[:name], :code => code)
    node.move_to_child_of(parent)
  end
end

# Third level for other
level_3_oth = [
  {:name => 'Engineering & Design',     :cat_code => 'XX.X1.XX'},
  {:name => 'Aquisition',               :cat_code => 'XX.X2.XX'},
  {:name => 'Construction',             :cat_code => 'XX.X3.XX'},
  {:name => 'Rehab/Renovaion',          :cat_code => 'XX.X4.XX'},
  {:name => 'Lease',                    :cat_code => 'XX.X5.XX'}
]
# Build the third level for each of the bus and fixed guideway nodes
%w{11.XX.XX 12.XX.XX}.each do |top_code|
  %w{XX.2X.XX XX.3X.XX XX.4X.XX XX.5X.XX XX.6X.XX}.each do |type_code|
    pc = top_code.split('.')[0]
    tc = type_code.split('.')[1]
    ac = type_code.split('.')[2]
    parent_code = "#{pc}.#{tc}.#{ac}"
    parent = TeamAliCode.find_by_code(parent_code)
  
    level_3_oth.each do |h|
      tc1 = "#{tc.first}#{h[:cat_code].split('.')[1].last}"
      ac1 = h[:cat_code].split('.')[2]
      code = "#{pc}.#{tc1}.#{ac1}"
      node = TeamAliCode.create!(:name => h[:name], :code => code)
      node.move_to_child_of(parent)
    end
  end
end

# Add the asset subtypes for the revenue rolling stock
# Third level for other
level_4_rrs = [
  {:name => 'Bus STD 40 Ft',          :cat_code => 'XX.XX.01'},
  {:name => 'Bus STD 35 Ft',          :cat_code => 'XX.XX.02'},
  {:name => 'Bus 30 Ft',              :cat_code => 'XX.XX.03'},
  {:name => 'Bus < 30 Ft',            :cat_code => 'XX.XX.04'},
  {:name => 'Bus School',             :cat_code => 'XX.XX.05'},
  {:name => 'Bus Articulated',        :cat_code => 'XX.XX.06'},
  {:name => 'Bus Commuter/Suburban',  :cat_code => 'XX.XX.07'},
  {:name => 'Bus Intercity',          :cat_code => 'XX.XX.08'},
  {:name => 'Bus Troley STD',         :cat_code => 'XX.XX.09'},
  {:name => 'Bus Trolley Artic.',     :cat_code => 'XX.XX.10'},
  {:name => 'Bus Double Deck',        :cat_code => 'XX.XX.11'},
  {:name => 'Bus Used',               :cat_code => 'XX.XX.12'},
  {:name => 'Bus School Used',        :cat_code => 'XX.XX.13'},
  {:name => 'Bus Dual Mode',          :cat_code => 'XX.XX.14'},
  {:name => 'Vans',                   :cat_code => 'XX.XX.15'},
  {:name => 'Sedan/Station Wagon',    :cat_code => 'XX.XX.16'},
  {:name => 'Light Rail Cars',        :cat_code => 'XX.XX.20'},
  {:name => 'Heavy Rail Cars',        :cat_code => 'XX.XX.21'},
  {:name => 'Commuter Rail Self Propelled - Elec',  :cat_code => 'XX.XX.22'},
  {:name => 'Commuter Rail Car Trailer',            :cat_code => 'XX.XX.23'},
  {:name => 'Commuter Locomotive Disel',            :cat_code => 'XX.XX.24'},
  {:name => 'Commuter Locomotive Electric',         :cat_code => 'XX.XX.25'},
  {:name => 'Commuter Rail Cars Used',              :cat_code => 'XX.XX.26'},
  {:name => 'Commuter Locomotive Used',             :cat_code => 'XX.XX.27'},
  {:name => 'Commuter Rail Self Prop - Diesel',     :cat_code => 'XX.XX.28'},
  {:name => 'Cable Car',              :cat_code => 'XX.XX.30'},
  {:name => 'People Mover',           :cat_code => 'XX.XX.31'},
  {:name => 'Car, Incline Railway',   :cat_code => 'XX.XX.32'},
  {:name => 'Ferry Boats',            :cat_code => 'XX.XX.33'},
  {:name => 'Transferred Vehicles',   :cat_code => 'XX.XX.39'},
  {:name => 'Spare Parts/ Assoc Capital Main. Items', :cat_code => 'XX.XX.40'}
]

# Build the fourth level for the revenue rolling stock
%w{11.XX.XX 12.XX.XX}.each do |top_code|
  %w{XX.11.XX XX.12.XX XX.13.XX XX.14.XX XX.15.XX XX.16.XX XX.18.XX}.each do |type_code|
    pc = top_code.split('.')[0]
    tc = type_code.split('.')[1]
    ac = type_code.split('.')[2]
    parent_code = "#{pc}.#{tc}.#{ac}"
    parent = TeamAliCode.find_by_code(parent_code)
  
    level_4_rrs.each do |h|
      ac1 = h[:cat_code].split('.')[2]
      code = "#{pc}.#{tc}.#{ac1}"
      node = TeamAliCode.create!(:name => h[:name], :code => code)
      node.move_to_child_of(parent)
    end
  end
end
