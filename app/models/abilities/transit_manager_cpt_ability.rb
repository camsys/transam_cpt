module Abilities
  class TransitManagerCptAbility
    include CanCan::Ability

    def initialize(user)

      can :manage, CapitalPlan do |c|
        user.organization_ids.include? c.organization_id
      end
      cannot :read_all, CapitalPlan

    end
  end
end