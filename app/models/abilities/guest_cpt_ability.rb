module Abilities
  class AuthorizedCptAbility
    include CanCan::Ability

    def initialize(user)

      #-------------------------------------------------------------------------
      # ALI Filters
      #-------------------------------------------------------------------------
      can :manage, UserActivityLineItemFilter do |f|
        f.creator == user
      end

    end
  end
end