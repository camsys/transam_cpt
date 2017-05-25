class ConstrainedCapitalPlanModule < BaseCapitalPlanModule
  def complete
    set_ali_is_complete_status true
  end

  def undo
    set_ali_is_complete_status false
  end


  def set_ali_is_complete_status is_complete_status
    #     Get all ALI associeated with the organizaton
    alis = ActivityLineItem.where(organization_id: @capital_plan_module.capital_plan.organization_id)

    #   Mark all the ALI is planning complete
    #   Save the ALIs
    alis.each_char { |ali|
      ali.is_planning_complete = is_complete_status
      ali.save
    }
  end
end