class BudgetRollup < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data(organization, params)
        
    # Generate the column labels for the plan years
    labels = ['Source']
    (current_planning_year_year..last_fiscal_year_year).each do |year|    
      labels << fiscal_year(year)
    end
    
    # Create an elibility service to evaluate the funding sources available
    # for this organization
    service = EligibilityService.new
    funding_sources = service.evaluate_organization_funding_sources(organization)
    
    # Start the data
    a = []
    funding_sources.each do |source|
      row = []
      row << source
      row <<  organization.budget(source)
      a << row.flatten
    end 
       
    puts labels.inspect
    puts a.inspect
                
    return {:labels => labels, :data => a}      
    
  end
  
end