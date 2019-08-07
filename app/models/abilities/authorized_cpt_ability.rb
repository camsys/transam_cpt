module Abilities
  class AuthorizedCptAbility
    include CanCan::Ability

    def initialize(user, organization_ids=[])
      
      if organization_ids.empty?
        organization_ids = user.organization_ids
      end

      #-------------------------------------------------------------------------
      # ALI Filters
      #-------------------------------------------------------------------------
      can :manage, UserActivityLineItemFilter do |f|
        f.creator == user
      end

    end
  end
end