
class SchedulerActionProxy < Proxy

  # General state variables

  # key for the asset being manipulated 
  attr_accessor     :object_key

  # action being invoked  
  attr_accessor     :action_id

  # reason asset is being replaced
  attr_accessor     :reason_id

  attr_accessor     :replace_subtype_id
  attr_accessor     :replace_fuel_type_id

  attr_accessor     :rehabilitate
  attr_accessor     :replace_fy_year
  
  # Basic validations. Just checking that the form is complete
  validates :action_id, :object_key, :presence => true 

  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
  end
                
end
