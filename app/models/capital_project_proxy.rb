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
    if project_subtype == '11'
      scope = '11.12.XX'
    elsif project_subtype == '12'
      scope = '11.16.XX'
    elsif project_subtype == '13'
      scope = '12.12.XX'
    elsif project_subtype == '14'
      scope = '12.16.XX'
      
    # Fleet Rebuild
    elsif project_subtype == '21'
      scope = '11.14.XX'
    elsif project_subtype == '22'
      scope = '12.14.XX'
    
    # Rail mid-life overhaul
    elsif project_subtype == '31'
      scope = '12.15.XX'
      
    # Vehicle Overhaul
    elsif project_subtype == '41'
      scope = '11.17.00'
    elsif project_subtype == '42'
      scope = '12.17.00'
      
    # Fleet Expansion
    elsif project_subtype == '51'
      scope = '11.13.XX'
    elsif project_subtype == '52'
      scope = '11.18.XX'
    elsif project_subtype == '53'
      scope = '12.13.XX'
    elsif project_subtype == '54'
      scope = '12.18.XX'
      
    # Facility Lease
    elsif project_subtype == '61'
      scope = '11.36.XX'
    elsif project_subtype == '62'
      scope = '11.46.XX'
    elsif project_subtype == '63'
      scope = '12.36.XX'
    elsif project_subtype == '64'
      scope = '12.46.XX'
      
    # Facility purchase
    elsif project_subtype == '71'
      scope = '11.32.XX'
    elsif project_subtype == '72'
      scope = '11.42.XX'
    elsif project_subtype == '73'
      scope = '12.32.XX'
    elsif project_subtype == '74'
      scope = '12.42.XX'

    # Facility rennovation
    elsif project_subtype == '81'
      scope = '11.34.XX'
    elsif project_subtype == '82'
      scope = '11.44.XX'
    elsif project_subtype == '83'
      scope = '12.34.XX'
    elsif project_subtype == '84'
      scope = '12.44.XX'

    # Transit Enhancements
    elsif project_subtype == '91'
      scope = '11.92.XX'
    elsif project_subtype == '92'
      scope = '11.95.XX'
    elsif project_subtype == '93'
      scope = '12.94.XX'
    elsif project_subtype == '94'
      scope = '12.92.XX'
    elsif project_subtype == '95'
      scope = '12.95.XX'
    elsif project_subtype == '96'
      scope = '12.94.XX'

    # Operating assistance
    elsif project_subtype == '101'
      scope = '30.09.00'
    elsif project_subtype == '102'
      scope = '30.09.80'
    elsif project_subtype == '103'
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
