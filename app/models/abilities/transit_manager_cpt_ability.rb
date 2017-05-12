module Abilities
  class TransitManagerCptAbility
    include CanCan::Ability

    def initialize(user)

      can :manage, CapitalPlan do |c|
        user.organization_ids.include? c.organization_id
      end
      can :complete_action, CapitalPlanAction do |a|
        (user.organization_ids.include? a.capital_plan.organization_id) && a.capital_plan_action_type.capital_plan_module_type != CapitalPlanModuleType.find_by(name: 'Final Review')
      end

      cannot :read_all, CapitalPlan

    end
  end
end