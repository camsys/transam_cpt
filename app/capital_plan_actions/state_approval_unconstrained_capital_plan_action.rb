class StateApprovalUnconstrainedCapitalPlanAction < BaseCapitalPlanAction

  def complete
    #   there is nothing to do at this point. SOGR for the completing agency is only locked once both state & agency have approved
  end

  def undo

  end
end