class BudgetSummary < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data(organization_id_list, params)
    
    # Get the array of fiscal years from the mixin
    fy_list = get_fiscal_years
    
    # Start the data
    a = []
    
    # Generate the column labels. These are from the FY array
    labels = ['Type']
    fy_list.each do |fy|
      labels << fy[0]
    end

    # Generate the summary, one for each state, federal reqest types
    FundingSourceType.all.each do |type|
      row = ["#{type.name} Budget"]
      # process each FY for this row
      fy_list.each do |fy|
        budget = Budget.where('organization_id IN (?) AND fy_year = ? AND funding_source_type_id =?', organization_id_list, fy[1], type.id).first
        if budget.nil?
          row << 0
        else
          row << budget.amount
        end
      end
      # add this row to the  data matrix
      a << row
    end
       
    # Add a row for each allocated amount for each type
    federal_row = ['Federal Requests']
    state_row = ['State Requests']
    # process each FY for this row
    fy_list.each do |fy|
      federal_amount = 0
      state_amount = 0
      projects = CapitalProject.where('organization_id IN (?) AND fy_year = ?', organization_id_list, fy[1])
      projects.each do |p|
        federal_amount += p.federal_request
        state_amount += p.state_request
      end
      federal_row << federal_amount
      state_row << state_amount
    end
    # add these rows to the  data matrix
    a << federal_row
    a << state_row
        
    puts labels.inspect
    puts a.inspect
    
    # Add the totals rows
    federal_row = ['Federal Budget Remaining']
    state_row = ['State Budget Remaining']
    fy_list.each_with_index do |fy, index|
      federal_row << a[0][index + 1] - a[2][index + 1]
      state_row << a[1][index + 1] - a[3][index + 1]
    end
    # add these rows to the data matrix
    a << federal_row
    a << state_row
            
    return {:labels => labels, :data => a}      
    
  end
  
end
