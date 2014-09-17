
class SchedulerActionProxy < Proxy

  # General state variables

  # key for the asset being manipulated 
  attr_accessor     :object_key

  # action being invoked  
  attr_accessor     :action_id

  # reason asset is being replaced
  attr_accessor     :reason_id
  # replacement asset type and fuel type
  attr_accessor     :replace_subtype_id
  attr_accessor     :replace_fuel_type_id

  # Number of years to extend the useful life  
  attr_accessor     :extend_eul_years  
  
  # year that the action will take place
  attr_accessor     :fy_year
  
  # Basic validations. Just checking that the form is complete
  validates :action_id, :object_key, :presence => true 

  def set_defaults(a)
    unless a.nil?
      asset = Asset.get_typed_asset(a)
      policy = asset.policy
      policy_item = policy.get_policy_item(asset)
      self.object_key = asset.object_key
      self.replace_subtype_id = asset.asset_subtype.id
      self.replace_fuel_type_id = asset.fuel_type.id if asset.type_of? :vehicle or asset.type_of? :support_vehicle
      self.extend_eul_years = 2
    end
    self.reason_id = 1 # default to end of EUL
  end
  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
  end
                
end
