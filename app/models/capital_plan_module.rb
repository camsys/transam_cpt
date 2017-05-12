class CapitalPlanModule < ActiveRecord::Base

  #------------------------------------------------------------------------------
  # Behaviors
  #------------------------------------------------------------------------------
  # Include the object key mixin
  include TransamObjectKey

  belongs_to :capital_plan_module_type

  belongs_to :capital_plan

  default_scope { order(:sequence) }

  def is_allowed?
    prev_action.completed_at.present?
  end

  def prev_action
    CapitalPlanModule.where(capital_plan_type_id: capital_plan_module_type.capital_plan_type_id).where('sequence < ?', self.sequence).order(:sequence).last
  end

  def next_action
    CapitalPlanModule.where(capital_plan_type_id: capital_plan_module_type.capital_plan_type_id).where('sequence > ?', self.sequence).order(:sequence).first
  end

end
