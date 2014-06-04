class CptReportRow
  
  attr_accessor  :fy_year, :state_request, :federal_request, :local_request
  
  def initialize(fy_year)
    self.fy_year = fy_year
    #self.count = 0
    self.state_request = 0
    self.federal_request = 0
    self.local_request = 0
    #self.id_list = []
  end
  
  def add(capital_project)
    #self.count += 1
    #self.id_list << capital_project.object_key
    self.state_request += capital_project.state_request
    self.federal_request += capital_project.federal_request
    self.local_request += capital_project.local_request
  end
  
end
