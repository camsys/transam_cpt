module Abilities
  class AuthorizedCptAbility
    include CanCan::Ability

    def initialize(user)

      #-------------------------------------------------------------------------
      # Capital Projects
      #-------------------------------------------------------------------------
      # Can create any project
      can [:create], CapitalProject

      # Can create any project
      can [:copy], CapitalProject do |cp|
        cp.sogr? == false and user.organization_ids.include?(cp.organization_id)
      end

      # Can update any project that is in their organization
      can [:update], CapitalProject do |cp|
        cp.can_update? and user.organization_ids.include?(cp.organization_id)
      end

      # Can add ALIs as long as it is not an SOGR project and it is in their organization
      can [:add_alis, :remove_alis], CapitalProject do |cp|
        cp.sogr? == false and cp.can_update? and user.organization_ids.include?(cp.organization_id)
      end

      # Can manage any project, ALI, and funding line item in their organization
      can [:add_comment, :add_document], CapitalProject do |cp|
        cp.can_update? and user.organization_ids.include?(cp.organization_id)
      end

      can [:destroy], CapitalProject do |cp|
        cp.sogr? == false and user.organization_ids.include?(cp.organization_id)
      end

      # Can manage any project, ALI, and funding line item in their organization
      can [:add_comment, :add_document], ActivityLineItem do |ali|
        ali.capital_project.can_update? and user.organization_ids.include?(ali.capital_project.organization_id)
      end

      can [:update, :destroy], ActivityLineItem do |ali|
        ali.capital_project.sogr? == false and ali.capital_project.can_update? and user.organization_ids.include?(ali.capital_project.organization_id)
      end

      can [:update_cost], ActivityLineItem do |ali|
        ali.capital_project.can_update? and user.organization_ids.include?(ali.capital_project.organization_id)
      end


    end
  end
end