class BudgetRollup < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data(organization, params)
        
    # Generate the column labels for the funding sources
    labels = ['Source']

    # Create an elibility service to evaluate the funding sources available
    # for this organization
    budgets = []
    service = EligibilityService.new
    funding_sources = service.evaluate_organization_funding_sources(organization)
    funding_sources.each do |fund|
      labels << fund.name
      budgets << organization.budget(fund)
    end

    # Start the data
    a = []    
    (current_planning_year_year..last_fiscal_year_year).each_with_index do |year, idx|    
      row = []
      row << fiscal_year(year)
      budgets.each do |budget|
        row << budget[idx]
      end
      a << row
    end
        #puts labels.inspect
    #puts a.inspect
                
    return {:labels => labels, :data => a}      
    
  end
  
end