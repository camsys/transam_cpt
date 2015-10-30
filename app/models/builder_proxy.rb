
class BuilderProxy < Proxy

  # General state variables

  # Starting FY to generate projects for
  attr_accessor     :start_fy

  # Type of asset type to process
  attr_accessor     :asset_types

  # Basic validations. Just checking that the form is complete
  validates :asset_types, :start_fy, :presence => true

  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
    self.asset_types ||= []
  end

end
