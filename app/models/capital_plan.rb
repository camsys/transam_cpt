class CapitalPlan < ActiveRecord::Base

  #------------------------------------------------------------------------------
  # Behaviors
  #------------------------------------------------------------------------------
  # Include the object key mixin
  include TransamObjectKey

  include FiscalYear

  include TransamFormatHelper

  belongs_to :organization
  belongs_to :capital_plan_type

  has_many :capital_plan_modules
  has_many :capital_plan_actions

  def self.current_plan(org_id)
    org = Organization.find_by(id: org_id)
    plan = CapitalPlan.find_by(fy_year: current_planning_year_year, organization_id: org_id, capital_plan_type_id: org.capital_plan_type_id)

    # generate a new plan for the current planning year if DNE
    if plan.nil?
      plan = CapitalPlan.create(fy_year: current_planning_year_year, organization_id: org_id, capital_plan_type_id: org.capital_plan_type_id)
      CapitalPlanModuleType.where(capital_plan_type_id: plan.capital_plan_type_id).each do |module_type|
        CapitalPlanModule.create(capital_plan_id: plan.id, capital_plan_module_type_id: module_type.id, sequence: module_type.sequence)
      end
      CapitalPlanActionType.where(capital_plan_type_id: plan.capital_plan_type_id).each do |action_type|
        CapitalPlanAction.create(capital_plan_id: plan.id, capital_plan_module_id: CapitalPlanModule.find_by(capital_plan_id: plan.id, capital_plan_module_type_id: action_type.capital_plan_module_type.id).id, capital_plan_action_type_id: action_type.id, sequence: action_type.sequence)
      end

    end

    plan
  end

  def allowed_sequences
    sequences = []

    capital_plan_modules.each do |m|
      unless m.capital_plan_module_type.strict_action_sequence
        sequences << m.capital_plan_actions.pluck(:object_key).permutation.to_a
      else
        sequences << [m.capital_plan_actions.pluck(:object_key)]
      end
    end
    puts sequences.inspect

    (sequences.first.product(*sequences[1..-1])).map{|s| s.flatten!}

  end


  def self.current_planning_year_year
    CapitalPlan.new.current_planning_year_year
  end

  def completed?
    !(capital_plan_modules.pluck(:completed_at).include? nil)
  end

  def capital_plan_action_completed?(action_type_id)
    capital_plan_actions.find_by(capital_plan_action_type_id: action_type_id).completed?
  end

  def capital_plan_module_completed?(module_type_id)
    capital_plan_modules.find_by(capital_plan_module_type_id: module_type_id).completed?
  end

  def to_s
    "#{organization.short_name} #{format_as_fiscal_year(fy_year)} Plan"
  end

  def system_actions
    capital_plan_actions.select{|a| a.capital_plan_action_type.class_name.constantize.new.system_action?}
  end
end
