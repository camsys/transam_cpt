class FundingCompleteConstrainedCapitalPlanAction < BaseCapitalPlanAction

  def system_action?
    true
  end

  def complete
    capital_plan = @capital_plan_action.capital_plan
    alis = ActivityLineItem.joins(:capital_project).where(capital_projects: {fy_year: capital_plan.fy_year, organization_id: capital_plan.organization_id})
    ali_count = alis.count
    funded_ali_count = 0
    alis.each do |ali|
      funded_ali_count += 1 if ali.pcnt_funded == 100
    end

    pcnt_funded = ali_count > 0 ? (funded_ali_count * 100.0 / ali_count).to_i : 100

    @capital_plan_action.update!(notes: "#{pcnt_funded}%")
  end

  def post_process
    if @capital_plan_action.notes == '100%'
      super
    end
  end

end