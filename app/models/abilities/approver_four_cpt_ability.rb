module Abilities
  class ApproverFourCptAbility
    include CanCan::Ability

    def initialize(user)

      can :complete_action, CapitalPlanAction do |a|
        a.capital_plan_action_type.name == 'Approver 4'
      end

    end
  end
end