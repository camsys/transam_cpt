module Abilities
  class AdminCptAbility
    include CanCan::Ability

    def initialize(user)

      cannot :manage, [CapitalProject, ActivityLineItem, CapitalPlan, CapitalPlanAction]

      self.merge Abilities::ManagerCptAbility.new(user)
    end
  end
end