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

lookup_tables = %w{capital_project_status_types milestone_types capital_project_types }

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

