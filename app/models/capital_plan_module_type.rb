class CapitalPlanModuleType < ActiveRecord::Base

  belongs_to :capital_plan_type
  has_many :capital_plan_action_types

  validates :capital_plan_type, :presence => true

  # All types that are available
  scope :active, -> { where(:active => true) }

  def to_s
    name
  end

end
