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
    
    # Fleet Replacement
    if project_subtype == '1'
      scope = '11.12.XX'
    elsif project_subtype == '2'
      scope = '11.16.XX'
    elsif project_subtype == '3'
      scope = '12.12.XX'
    elsif project_subtype == '4'
      scope = '12.16.XX'
      
    # Fleet Rebuild
    elsif project_subtype == '5'
      scope = '11.14.XX'
    elsif project_subtype == '6'
      scope = '12.14.XX'
    
    # Rail mid-life overhaul
    elsif project_subtype == '7'
      scope = '12.15.XX'
      
    # Vehicle Overhaul
    elsif project_subtype == '8'
      scope = '11.17.00'
    elsif project_subtype == '9'
      scope = '12.17.00'
      
    # Fleet Expansion
    elsif project_subtype == '10'
      scope = '11.13.XX'
    elsif project_subtype == '11'
      scope = '11.18.XX'
    elsif project_subtype == '12'
      scope = '12.13.00'
    elsif project_subtype == '13'
      scope = '12.18.00'
      
    # Facility Lease
    elsif project_subtype == '14'
      scope = '11.36.XX'
    elsif project_subtype == '15'
      scope = '11.46.XX'
    elsif project_subtype == '16'
      scope = '12.36.00'
    elsif project_subtype == '17'
      scope = '12.46.00'
      
    # Facility purchase
    elsif project_subtype == '18'
      scope = '11.32.XX'
    elsif project_subtype == '19'
      scope = '11.42.XX'
    elsif project_subtype == '20'
      scope = '12.32.00'
    elsif project_subtype == '21'
      scope = '12.42.00'

    # Facility rennovation
    elsif project_subtype == '22'
      scope = '11.34.XX'
    elsif project_subtype == '23'
      scope = '11.44.XX'
    elsif project_subtype == '24'
      scope = '12.34.00'
    elsif project_subtype == '25'
      scope = '12.44.00'

    # Operating assistance
    elsif project_subtype == '27'
      scope = '30.09.00'
    elsif project_subtype == '28'
      scope = '30.09.80'
    elsif project_subtype == '29'
      scope = '30.80.01'
    else
      scope = '1X.XX.XX'
    end  
  end
  
  protected
             
  # Set resonable defaults for a new capital project
  def set_defaults

  end    
              
end
