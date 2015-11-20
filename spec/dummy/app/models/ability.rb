# Dummy App Ability File to give permissions for testing

class Ability
  include CanCan::Ability

  def initialize(user)

    can :manage, :all

  end
end
