class BudgetBurndown < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data(organization, params)
        
    funding_source = params[:funding_source]
     
    # Generate the column labels for the funding sources
    labels = [funding_source.name, 'Funds', 'Available', 'Alloc.']

    # Start the data
    a = []
    cumulative_total = 0    
    cumulative_spent = 0    
    (current_planning_year_year..last_fiscal_year_year).each_with_index do |year, idx|    
      row = []
      row << fiscal_year(year)
      amount = 0
      budget = BudgetAmount.find_by(:organization => organization, :funding_source => funding_source, :fy_year => year)      
      if budget
        amount = budget.amount
        cumulative_total += budget.amount
        cumulative_spent += budget.spent
      end
      row << cumulative_total
      row << cumulative_total - cumulative_spent
      row << amount
      a << row
    end
                
    return {:labels => labels, :data => a}      
    
  end
  
end