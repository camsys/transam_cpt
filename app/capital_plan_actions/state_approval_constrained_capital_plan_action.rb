class StateApprovalConstrainedCapitalPlanAction < BaseCapitalPlanAction

  def complete
    #   There is nothing to do when the state indicates this is complete. Only once both the state and agency agree it is complete do we "lock" this orgs ALIs
  end

  def undo
    # If the state indicates this is incomplete and it must be undone then runde the module's undo for it is only the module that really works
    @capital_plan_action.capital_plan_module.undo
  end
end