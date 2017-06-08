class CapitalPlanActionType < ActiveRecord::Base

  belongs_to :capital_plan_type
  belongs_to :capital_plan_module_type

  validates :capital_plan_type, :presence => true
  validates :capital_plan_module_type, :presence => true

  # All types that are available
  scope :active, -> { where(:active => true) }

  def to_s
    name
  end

  def system_action?
    class_name.constantize.new.system_action?
  end

end
