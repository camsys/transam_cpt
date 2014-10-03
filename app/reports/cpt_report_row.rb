class CptReportRow
  
  attr_accessor  :fy_year, :state_request, :federal_request, :local_request, :estimated_cost, :total_requested, :total_approved
  
  def initialize(fy_year)
    self.fy_year = fy_year
    #self.count = 0
    self.state_request = 0
    self.federal_request = 0
    self.local_request = 0
    
    self.estimated_cost = 0
    self.total_requested = 0
    self.total_approved = 0
    #self.id_list = []
  end
  
  def add(capital_project)
    #self.count += 1
    #self.id_list << capital_project.object_key
    self.state_request += capital_project.state_request
    self.federal_request += capital_project.federal_request
    self.local_request += capital_project.local_request

    self.estimated_cost += capital_project.total_cost
    cp_total_requested = capital_project.state_request + capital_project.federal_request + capital_project.local_request
    self.total_requested += cp_total_requested
    self.total_approved += capital_project.capital_project_status_type_id == 4 ? cp_total_requested : 0
    
  end
  
end
