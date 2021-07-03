
class BuilderProxy < Proxy

  # General state variables

  # organization
  attr_accessor     :organization_id

  # starting Scenario
  attr_accessor     :scenario_id

  # FYs to generate projects for
  attr_accessor     :start_fy
  attr_accessor     :range_fys

  # Type of asset type to process
  attr_accessor     :asset_types

  attr_accessor     :class_names

  attr_accessor     :fta_asset_classes

  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
    self.asset_types ||= []
    self.range_fys = 11 unless self.range_fys.to_i > 0 # the default should be 12 years which is 11 for the range + 1 for the starting year
  end

end
