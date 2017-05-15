class CapitalPlanAction < ActiveRecord::Base

  #------------------------------------------------------------------------------
  # Behaviors
  #------------------------------------------------------------------------------
  # Include the object key mixin
  include TransamObjectKey


  belongs_to :capital_plan_action_type

  belongs_to :capital_plan_module
  belongs_to :capital_plan

  default_scope { joins(:capital_plan_module).order('capital_plan_modules.sequence', 'capital_plan_actions.sequence') }

  def system_action?
    capital_plan_action_type.system_action?
  end

  def completed?
    completed_at.present?
  end

  def is_allowed?

    return true if system_action?

    if capital_plan_action_type.prev_action_required
      (prev_action.nil? || prev_action.completed_at.present?) && completed_at.nil?
    else
      prev_module = capital_plan.capital_plan_modules.find_by(sequence: capital_plan_module.sequence-1)
      (prev_module.nil? || prev_module.completed_at.present?) && completed_at.nil?
    end
  end

  def is_undo_allowed?

    if capital_plan_action_type.prev_action_required
      (next_action.nil? || next_action.completed_at.nil?) && completed_at.present?
    else
      next_module = capital_plan.capital_plan_modules.find_by(sequence: capital_plan_module.sequence+1)
      (next_module.nil? || next_module.capital_plan_actions.pluck(:completed_at).uniq == [nil]) && completed_at.present?
    end
  end

  def prev_action
    idx = capital_plan.capital_plan_actions.index(self)-1
    if idx > -1
      capital_plan.capital_plan_actions[idx]
    end

  end

  def next_action
    idx = capital_plan.capital_plan_actions.index(self)+1
    if idx < capital_plan.capital_plan_actions.length
      capital_plan.capital_plan_actions[idx]
    end
  end

end
