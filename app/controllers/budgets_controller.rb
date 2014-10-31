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
    
    # generate the budget rollup report
    @report = Report.find_by_class_name('BudgetRollup')
    report_instance = @report.class_name.constantize.new
    @data = report_instance.get_data(@organization, {})
         
  end    
  
  # Called when the user wants to update a budget for a funding source
  def alter
    
    @funding_source = FundingSource.find_by_object_key(params[:id])
    @budget = []
    @organization.budget(@funding_source).each do |amount|
      @budget << amount / 1000
    end

    render partial: 'budget_modal_form'
    
  end
  
  def set

    @funding_source = FundingSource.find_by_object_key(params[:funding_source])
    # process through the budget amounts
    (current_planning_year_year..last_fiscal_year_year).each do |year|
      new_amount = params[year.to_s].to_i * 1000
      # update the budget
      budget_amount = BudgetAmount.find_by(:organization => @organization, :funding_source => @funding_source, :fy_year => year)
      if budget_amount.nil?
        budget_amount = BudgetAmount.new({:organization => @organization, :funding_source => @funding_source, :fy_year => year})
      end
      budget_amount.amount = new_amount
      budget_amount.save
    end
    
    redirect_to budgets_url, :format => 'js'
          
  end
  
end