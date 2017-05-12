class CapitalPlan < ActiveRecord::Base

  #------------------------------------------------------------------------------
  # Behaviors
  #------------------------------------------------------------------------------
  # Include the object key mixin
  include TransamObjectKey

  include FiscalYear

  belongs_to :organization
  belongs_to :capital_plan_type

  has_many :capital_plan_modules
  has_many :capital_plan_actions

  def self.current_plan(org_id)
    plan = CapitalPlan.find_by(fy_year: current_planning_year_year, organization_id: org_id)

    # generate a new plan for the current planning year if DNE
    if plan.nil?
      org = Organization.find_by(id: org_id)
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

  def system_actions
    capital_plan_actions.select{|a| a.class_name.constantize.new.system_action?}
  end
end
