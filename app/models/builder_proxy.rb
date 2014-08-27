
class BuilderProxy < Proxy

  # General state variables
 
  # Type of financing projects to generate
  attr_accessor     :finance_type
  
  # Type of asset type to process
  attr_accessor     :asset_types
  
  # Basic validations. Just checking that the form is complete
  validates :asset_types, :finance_type, :presence => true 

  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
    self.asset_types ||= []
    self.finance_type ||= 1
  end
                
end
