class AssetOverridePreparationCapitalPlanAction < BaseCapitalPlanAction

  def complete
    @capital_plan_action.capital_plan.capital_plan_actions.find_by(capital_plan_action_type_id: CapitalPlanActionType.find_by(class_name: 'AssetPreparationCapitalPlanAction').id).update(completed_at: Time.now, completed_by_user_id: @user.id)
  end

end