class CapitalPlanModuleType < ActiveRecord::Base

  belongs_to :capital_plan_type

  # All types that are available
  scope :active, -> { where(:active => true) }

  def to_s
    name
  end

end
