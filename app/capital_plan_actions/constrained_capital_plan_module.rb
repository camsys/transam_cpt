class ConstrainedCapitalPlanModule < BaseCapitalPlanModule
  def complete
    set_ali_is_complete_status true
  end

  def undo_complete
    set_ali_is_complete_status false
  end


  def set_ali_is_complete_status is_complete_status
    #     Get all ALI associated with the organizaton
    #   Mark all the ALI is planning complete
    #   Save the ALIs
    ActivityLineItem.joins(:capital_project).where(capital_projects: {organization_id: @capital_plan_module.capital_plan.organization_id, fy_year: @capital_plan_module.capital_plan.fy_year}).update_all(is_planning_complete: is_complete_status)
  end
end