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

  def is_allowed?(hypothetical_finished_seq=[])

    return true if system_action?
    return false if capital_plan.completed?

    # check prev_module
    prev_module_check = (prev_module.nil? || prev_module.completed_at.present?) && completed_at.nil?
    unless hypothetical_finished_seq.length > 0
      if capital_plan_module.capital_plan_module_type.strict_action_sequence?
        prev_module_check && (sequence == 1 || prev_action.completed_at.present?)
      else
        prev_module_check
      end
    else
      sys_actions_completed = true
      capital_plan.capital_plan_actions[0..hypothetical_finished_seq.length-1].each do |action|
        if action.system_action?
          sys_actions_completed = (sys_actions_completed & action.completed?)
        end
      end
      obj_key_actions = capital_plan.capital_plan_actions.select{|a| !a.system_action?}.map(&:object_key)

      prev_check = prev_module.nil? || (obj_key_actions & hypothetical_finished_seq) == obj_key_actions && sys_actions_completed
      if capital_plan_module.capital_plan_module_type.strict_action_sequence?
        idx = hypothetical_finished_seq.index(prev_action.object_key)
        prev_check && (sequence == 1 || idx )
      else
        prev_check
      end
    end
  end

  def is_undo_allowed?(hypothetical_finished_seq=[])

    return false if capital_plan.completed?

    finished_actions = hypothetical_finished_seq.length > 0 ? hypothetical_finished_seq : capital_plan.capital_plan_actions.where('capital_plan_actions.completed_at IS NOT NULL').pluck(:object_key)
    finished_actions.index(object_key) == finished_actions.length-1
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

  def prev_module
    capital_plan.capital_plan_modules.find_by(sequence: capital_plan_module.sequence-1)
  end

  def next_module
    capital_plan.capital_plan_modules.find_by(sequence: capital_plan_module.sequence+1)
  end
end
