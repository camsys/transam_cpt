module Abilities
  class AdminCptAbility
    include CanCan::Ability

    def initialize(user)

      cannot :manage, [CapitalProject, ActivityLineItem, CapitalPlan, CapitalPlanAction]

      self.merge Abilities::AuthorizedCptAbility.new(user)
      self.merge Abilities::ManagerCptAbility.new(user)

      # can do anything on capital plans
      can :manage, [CapitalPlan, CapitalPlanAction]
    end
  end
end