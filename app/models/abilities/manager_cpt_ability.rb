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
      # Capital Projects
      #-------------------------------------------------------------------------

      can [:update, :destroy], ActivityLineItem do |ali|
        ali.capital_project.sogr? == false and ali.capital_project.can_update?and !ali.is_planning_complete and !ali.pinned?
      end

      can [:update_cost], ActivityLineItem do |ali|
        ali.capital_project.can_update? and !ali.is_planning_complete and !ali.pinned?
      end

      can [:pin], ActivityLineItem do |ali|
        ali.can_pin? and ali.capital_project.can_update? and !ali.is_planning_complete
      end


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