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
    start_year = funding_line_item_list.first.fy_year
    last_year = last_fiscal_year_year
    years = (start_year..last_year).to_a
    
    # Generate the column labels and rows for each metric. 
    labels = ['FY', 'Granted', 'Spent', 'Committed', 'Balance']
        
    # Store the results
    a = []
    
    # process each FY 
    balance = 0
    years.each_with_index do |fy|
      
      # Create a new row for this fiscal year
      row = []
      labels.each_with_index do |l, idx|
        if idx == 0
          row << fiscal_year(fy)
        else
          row << 0
        end
      end

      # Add the row to the results
      a << row
      
      funding_line_items = funding_line_item_list.where('fy_year = ?', fy)
      funding_line_items.each do |fli|
        row[1] += fli.amount
        row[2] += fli.spent
        row[3] += fli.committed
        row[4] += fli.available
      end
      balance += row[1] - (row[2] + row[3])
      row[4] = balance
    end
           
    puts labels.inspect
    puts a.inspect
            
    return {:labels => labels, :data => a}      
    
  end
  
end
