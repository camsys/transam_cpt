class CashFlowForecast < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data(organization, params)
    
    funding_line_items = FundingLineItem.where('organization_id = ?', organization.id)
    return get_data_from_result_list(funding_line_items)
    
  end
  
  def get_data_from_result_list(funding_line_item_list)
    
    # Get the array of fiscal years from the mixin
    fy_list = get_fiscal_years
        
    # Generate the column labels and rows for each metric. 
    labels = ['FY', 'State Allocated', 'State Spent', 'State Committed', 'State Available', 'Federal Allocated', 'Federal Spent', 'Federal Committed', 'Federal Available']
        
    # Store the results
    a = []
    
    # process each FY 
    fy_list.each_with_index do |fy|
      
      # Create a new row for this fiscal year
      row = []
      labels.each_with_index do |l, idx|
        if idx == 0
          row << fy[0]
        else
          row << 0
        end
      end
      
      # Add the row to the results
      a << row
      
      funding_line_items = funding_line_item_list.where('fy_year = ?', fy[1])
      funding_line_items.each do |fli|
        if fli.federal?
          row[5] += fli.amount
          row[6] += fli.spent
          row[7] += fli.committed
          row[8] += fli.available
        else
          row[1] += fli.amount
          row[2] += fli.spent
          row[3] += fli.committed
          row[4] += fli.available
        end
      end
    end
           
    puts labels.inspect
    puts a.inspect
            
    return {:labels => labels, :data => a}      
    
  end
  
end
