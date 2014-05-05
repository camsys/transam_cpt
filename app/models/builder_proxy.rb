
class BuilderProxy < Proxy

  # General state variables
 
  # Type of capital projects to generate
  attr_accessor     :project_type
  
  # Type of asset type to process
  attr_accessor     :asset_type_id
  
  # Basic validations. Just checking that the form is complete
  validates :asset_type_id, :project_type, :presence => true 

  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
  end
                
end
