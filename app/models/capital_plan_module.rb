class CapitalPlanModule < ActiveRecord::Base

  #------------------------------------------------------------------------------
  # Behaviors
  #------------------------------------------------------------------------------
  # Include the object key mixin
  include TransamObjectKey

  belongs_to :capital_plan_module_type

  belongs_to :capital_plan

  has_many :capital_plan_actions

  default_scope { order(:sequence) }

  def is_allowed?
    !(capital_plan_actions.pluck(:completed_at).include? nil)
  end

  def prev_module
    capital_plan.capital_plan_modules.where('sequence < ?', self.sequence).order(:sequence).last
  end

  def next_module
    capital_plan.capital_plan_modules.where('sequence > ?', self.sequence).order(:sequence).first
  end

end
