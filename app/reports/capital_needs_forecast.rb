class CapitalNeedsForecast < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data_from_result_list(capital_project_list)
    
    # Capital Needs by year
    state_names = CapitalProject.state_names
    a = []
    labels = ['Fiscal Year']
    state_names.each do |name|
      labels << name.humanize
    end
        
    (current_planning_year_year..last_fiscal_year_year).each do |year|
      row = []
      row << fiscal_year(year)      
      state_names.each do |state|
        total = 0
        # get the capital projects for this analysis year and state
        capital_projects =  capital_project_list.where('fy_year = ? AND state = ?', year, state)
        capital_projects.find_each do |cp|
          total += cp.total_cost
        end
        row << total
      end
      a << row
    end
    
    return {:labels => labels, :data => a}      
    
  end
  
  def get_data(organization_id_list, params)
    
    capital_projects = CapitalProject.where('capital_projects.organization_id IN (?)', organization_id_list)
    return get_data_from_result_list(capital_projects)
    
  end
  
end
