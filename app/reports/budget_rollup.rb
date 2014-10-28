class BudgetRollup < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data(organization, params)
    
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
    FundingSource.all.each do |source|
      row = [source.name]
      # process each FY for this row
      fy_list.each do |fy|
        budget = BudgetAmount.where('organization_id = ? AND fy_year = ? AND funding_source_id =?', organization.id, fy[1], source.id).first
        if budget.nil?
          row << 0
        else
          row << budget.amount
        end
      end
      # add this row to the  data matrix
      a << row
    end
       
    puts labels.inspect
    puts a.inspect
    
    # Add the total row
    row = ['Total']
    fy_list.each_with_index do |fy, index|
      row << a[0][index + 1] + a[1][index + 1]
    end
    a << row
            
    return {:labels => labels, :data => a}      
    
  end
  
end