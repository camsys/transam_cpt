
class BuilderProxy < Proxy

  # General state variables

  # organization
  attr_accessor     :organization_id

  # Starting FY to generate projects for
  attr_accessor     :start_fy

  # Type of asset type to process
  attr_accessor     :asset_types

  attr_accessor     :fta_asset_categories

  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
    self.asset_types ||= []
  end

end
