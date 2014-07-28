class CapitalProjectProxy < Proxy
    
  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
   
  # Step 1: Project characteristics
  attr_accessor :name
  attr_accessor :fiscal_year
  attr_accessor :mode
  attr_accessor :capital_project_type

  # Step 2
  attr_accessor :category
 
  # Step 3
  attr_accessor :team_ali_code
  
  # Step 4
  attr_accessor :description
  attr_accessor :justification
    
  def scope(step = 1)
    if step == 1
      x = nil
    elsif step == 2
      code = "1#{mode}.XX.XX"
      x = TeamAliCode.find_by_code(code) 
    elsif step == 3
      code = "1#{mode}.#{category}X.XX"
      x = TeamAliCode.find_by_code(code) 
    elsif step > 3
      x = TeamAliCode.find(team_ali_code)            
    end
    x     
  end 
   
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
             
  protected
             
  # Set resonable defaults for a new capital project
  def set_defaults

  end    
              
end
