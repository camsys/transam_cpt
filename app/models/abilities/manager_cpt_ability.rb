module Abilities
  class ManagerCptAbility
    include CanCan::Ability

    def initialize(user)

      self.merge Abilities::AuthorizedCptAbility.new(user, Organization.ids)

      #-------------------------------------------------------------------------
      # ALI Filters
      #-------------------------------------------------------------------------

      can :manage, UserActivityLineItemFilter


      #-------------------------------------------------------------------------
      # Capital Plans
      #-------------------------------------------------------------------------

      can :manage, CapitalPlan do |c|
        !c.completed?
      end
      can :complete_action, CapitalPlanAction do |a|
        (a.capital_plan_action_type.roles.split(',') & user.roles_name).any?
      end

      cannot :complete_action, CapitalPlanAction do |a|
        a.capital_plan_action_type.class_name == 'AssetOverridePreparationCapitalPlanAction' && a.completed? && a.prev_action.completed_pcnt == 100
      end

    end
  end
end