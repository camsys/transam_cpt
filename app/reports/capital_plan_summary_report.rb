class CapitalPlanSummaryReport < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data_from_result_list(capital_project_list)
    
    # Capital Needs by year
    a = []
    labels = ['Year', 'Replace', 'Rehab', 'Remove', 'Cost']
        
    start_year = current_fiscal_year_year + 1
    (start_year..last_fiscal_year_year).each do |year|
      num_replace = 0
      num_rehab = 0
      num_other = 0
      num_remove = 0
      cost = 0
      # get the capital projects for this analysis year
      capital_projects =  capital_project_list.where('fy_year = ?', year)
      capital_projects.find_each do |cp|
        cp.activity_line_items.each do |ali|
          if cp.capital_project_type.id == 1
            num_replace += ali.assets.count
          elsif cp.capital_project_type.id == 3
            num_rehab += ali.assets.count
          end
        end
        cost += cp.total_estimated_cost
      end
      unless capital_project_list.empty?
        num_remove = Asset.where('organization_id = ? AND scheduled_disposition_year = ?', capital_project_list.first.organization.id, year).count
      end
      a << [year, num_replace, num_rehab, num_remove, cost]
    end
    
    puts a.inspect
    
    return {:labels => labels, :data => a}      
    
  end
  
  def get_data(organization_id_list, params)
    
    capital_projects = CapitalProject.where('capital_projects.organization_id IN (?)', organization_id_list)
    return get_data_from_result_list(capital_projects)
    
  end
  
end
