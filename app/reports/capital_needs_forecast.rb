class CapitalNeedsForecast < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data_from_result_list(capital_project_list)
    
    # Capital Needs by year
    a = []
    #labels = ['Fiscal Year', 'State', 'Federal', 'Local']
    labels = ['Fiscal Year', 'Estimated', 'Requested', 'Approved']
        
    (current_fiscal_year_year..last_fiscal_year_year).each do |year|
      report_row = CptReportRow.new(year)
      # get the capital projects for this analysis year
      capital_projects =  capital_project_list.where('fy_year = ?', year)
      capital_projects.find_each do |cp|
        report_row.add(cp)
      end
      a << [fiscal_year(year), report_row.estimated_cost, report_row.total_requested, report_row.total_approved]
    end
    
    return {:labels => labels, :data => a}      
    
  end
  
  def get_data(organization_id_list, params)
    
    capital_projects = CapitalProject.where('capital_projects.organization_id IN (?)', organization_id_list)
    return get_data_from_result_list(capital_projects)
    
  end
  
end
