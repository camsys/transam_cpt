
class PolicyDistributerProxy < Proxy
  # General state variables
 
  # Type of asset type to process
  attr_accessor     :policy, :apply_policies, :build_projects

  validates :policy, :presence => true

  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
  end
end