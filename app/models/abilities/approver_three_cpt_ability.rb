module Abilities
  class ApproverThreeCptAbility
    include CanCan::Ability

    def initialize(user)

      can :complete_action, CapitalPlanAction do |a|
        a.capital_plan_action_type.name == 'Approver 3'
      end

    end
  end
end