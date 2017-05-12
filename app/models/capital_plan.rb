class CapitalPlan < ActiveRecord::Base

  #------------------------------------------------------------------------------
  # Behaviors
  #------------------------------------------------------------------------------
  # Include the object key mixin
  include TransamObjectKey

  belongs_to :organization
  belongs_to :capital_plan_type

  has_many :capital_plan_modules
  has_many :capital_plan_actions
end
