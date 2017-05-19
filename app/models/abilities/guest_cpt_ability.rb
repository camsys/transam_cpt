module Abilities
  class GuestCptAbility
    include CanCan::Ability

    def initialize(user)

      #-------------------------------------------------------------------------
      # ALI Filters
      #-------------------------------------------------------------------------
      can :manage, UserActivityLineItemFilter do |f|
        f.creator == user
      end

      if user.organization.organization_type == OrganizationType.find_by(class_name: 'Grantor')
        can :read_all, CapitalPlan
      end

    end
  end
end