class BudgetsController < OrganizationAwareController

  add_breadcrumb "Home", :root_path
  
  # Include the fiscal year mixin
  include FiscalYear
   
  # Only entry point for users 
  def index

    add_breadcrumb "Budget Forecast"
    
    # Generate a table of budget amounts
    @columns = []
    @columns << "Source"
    @totals = []
    @totals << "Totals"
    (current_planning_year_year..last_fiscal_year_year).each do |year|
      @columns << fiscal_year(year)
      @totals << 0
    end
     
    @budgets = []
    # Create an elibility service to evaluate the funding sources available
    # for this organization
    service = EligibilityService.new
    funding_sources = service.evaluate_organization_funding_sources(@organization)
    funding_sources.each do |source|
      row = []
      row << source
      row <<  @organization.budget(source)
      @budgets << row.flatten
    end 
    
    @budgets.each do |row|
      row.each_with_index do |col, idx|
        if idx > 0
          @totals[idx] += row[idx]
        end
      end
    end
    
  end    
end