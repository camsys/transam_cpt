class CapitalNeedsForecast < AbstractReport
  
  # Include the fiscal year mixin
  include FiscalYear
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data_from_result_list(capital_project_list)
    
    # Capital Needs by year
    analysis_year = current_fiscal_year_year
    last_year = analysis_year + MAX_FORECASTING_YEARS

    a = []
    labels = ['Fiscal Year', 'State', 'Federal', 'Local']
        
    (analysis_year..last_year).each do |year|
      report_row = CptReportRow.new(year)
      # get the capital projects for this analysis year
      capital_projects =  capital_project_list.where('fy_year = ?', year)
      capital_projects.find_each do |cp|
        report_row.add(cp)
      end
      a << [fiscal_year(year), report_row.state_request, report_row.federal_request, report_row.local_request]
    end
    
    return {:labels => labels, :data => a}      
    
  end
  
  def get_data(organization_id_list, params)
    
    capital_projects = CapitalProject.where('capital_projects.organization_id IN (?)', organization_id_list)
    return get_data_from_result_list(capital_projects)
    
  end
  
end
