class AssetPreparationCapitalPlanAction < BaseCapitalPlanAction

  def system_action?
    true
  end

  def complete
    report = AuditResultsSummaryReport.new
    audit_results = report.get_data(audit, [@capital_plan_action.capital_plan.organization], 'Asset', {disposition_date: nil},{})
    audit_results[1].each do |row|
      pcnt_passed = ((row[3] / row[2].to_f) * 100).truncate
    end

    @capital_plan_action.update(notes: "#{pcnt_passed}%")
  end

  def post_process
    if @capital_plan_action.notes == '100%'
      super
    end
  end

end