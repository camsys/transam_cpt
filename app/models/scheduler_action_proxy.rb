
class SchedulerActionProxy < Proxy

  # key for the asset being manipulated
  attr_accessor     :object_key

  # action being invoked
  attr_accessor     :action_id

  # reason asset is being replaced
  attr_accessor     :reason_id

  # replacement asset type and fuel type
  attr_accessor     :replace_with_new
  attr_accessor     :replace_subtype_id
  attr_accessor     :replace_fuel_type_id

  # Number of years to extend the useful life
  attr_accessor     :extend_eul_years

  # year that the action will take place
  attr_accessor     :fy_year

  # Cost for the activity (replacement and rehabilitation only)
  attr_accessor     :replace_cost
  attr_accessor     :rehab_cost

  # Basic validations. Just checking that the form is complete
  validates :action_id, :object_key, :presence => true

  def set_defaults(a)
    unless a.nil?
      asset = Asset.get_typed_asset(a)
      self.object_key = asset.object_key
      self.replace_subtype_id = policy_item.replace_asset_subtype_id
      self.replace_fuel_type_id = policy_item.replace_fuel_type_id if asset.type_of? :rolling_stock

      if asset.scheduled_replacement_cost.blank?
        self.replace_cost = policy_item.replacement_cost
      else
        self.replace_cost = asset.scheduled_replacement_cost
      end

      if asset.scheduled_rehabilitation_cost.blank?
        self.rehab_cost = policy_item.rehabilitation_cost
      else
        self.rehab_cost = asset.scheduled_rehabilitation_cost
      end

      self.replace_with_new = 1
      self.extend_eul_years = policy_item.extended_service_life_years
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
