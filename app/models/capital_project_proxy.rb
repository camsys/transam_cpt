class CapitalProjectProxy < Proxy
    
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
 
  # Type of project to generate
  attr_accessor  :capital_project_type
  # Type of sub project to generate
  attr_accessor  :project_subtype
  # project characteristics
  attr_accessor :name
  attr_accessor :fiscal_year
  attr_accessor :description
  attr_accessor :justification
    
  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
    set_defaults
  end
                
  def assign_attributes(attrs = {})
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
  end    
           
  def save
    true
  end
           
  def scope
    TeamAliCode.find_by_code(scope_code)
  end      
     
  def scope_code
    if capital_project_type == '1'
      scope = '11.12.XX'
    elsif capital_project_type == '2'
      scope = '11.16.XX'
    elsif capital_project_type == '3'
      scope = '12.12.XX'
    elsif capital_project_type == '4'
      scope = '12.16.XX'
    elsif capital_project_type == '5'
      scope = '11.14.XX'
    elsif capital_project_type == '6'
      scope = '12.14.XX'
    elsif capital_project_type == '7'
      scope = '12.15.XX'
    elsif capital_project_type == '8'
      scope = '11.13.XX'
    elsif capital_project_type == '9'
      scope = '11.18.XX'
    elsif capital_project_type == '10'
      scope = '12.13.XX'
    elsif capital_project_type == '11'
      scope = '12.18.XX'
    elsif capital_project_type == '12'
      scope = '11.17.00'
    elsif capital_project_type == '13'
      scope = '12.17.00'
    end  
  end
  
  protected
             
  # Set resonable defaults for a new capital project
  def set_defaults

  end    
              
end
