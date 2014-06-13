class CapitalNeedsForecastRollup < AbstractReport
  
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
    
    # Generate the labels. These are from the FY array
    labels = ['Type']
    fy_list.each do |fy|
      labels << fy[0]
    end

    # Generate the summary, one for each state, federal, local reqest types
    %w{State Federal Local Total}.each do |type|
      row = [type]
      # process each FY for this row
      fy_list.each do |fy|
        row << 0
      end
      # add this row to the  data matrix
      a << row
    end
       
    #puts a[0].inspect
    #puts a[1].inspect
    #puts a[2].inspect
    #puts a[3].inspect
      
    # process each FY for this row
    fy_list.each_with_index do |fy, index|
      capital_projects = CapitalProject.where('organization_id = ? AND fy_year = ?', organization.id, fy[1])
      capital_projects.each do |cp|
        a[0][index + 1] += cp.state_request    
        a[1][index + 1] += cp.federal_request    
        a[2][index + 1] += cp.local_request
        a[3][index + 1] += cp.total_request    
      end      
    end
        
    return {:labels => labels, :data => a}      
    
  end
  
end
