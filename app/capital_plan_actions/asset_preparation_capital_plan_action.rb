class AssetPreparationCapitalPlanAction < BaseCapitalPlanAction

  def system_action?
    true
  end

  def complete
    report = AuditResultsSummaryReport.new

    pcnts_passed = []
    Audit.all.each do |audit|
      audit_results = report.get_data(audit, [@capital_plan_action.capital_plan.organization_id], 'Asset', {disposition_date: nil},{})
      total_assets = 0
      passed_assets = 0
      audit_results[1].each do |row|
        total_assets += row[2]
        passed_assets += row[3]
      end
      if audit_results[1].length > 0
        pcnt_passed = ((passed_assets / total_assets.to_f) * 100).truncate
        pcnts_passed << pcnt_passed
      end
    end


    total_pcnt_passed = pcnts_passed.reduce(:+) / pcnts_passed.size.to_f
    total_pcnt_passed = (total_pcnt_passed + 0.5).to_i

    if @user.organization.organization_type.class_name == 'Grantor'
      url = Rails.application.routes.url_helpers.funding_buckets_url(funds_filter: 'funds_overcommitted')
    else
      url = Rails.application.routes.url_helpers.my_funds_funding_buckets_url(funds_filter: 'funds_overcommitted')
    end

    @capital_plan_action.update(completed_pcnt: total_pcnt_passed, notes: "<a href='#{url}' style='color:red;'>#{total_pcnt_passed}%</a>")

    if @capital_plan_action.completed_pcnt == 100
      @capital_plan_action.capital_plan.capital_plan_actions.find_by(capital_plan_action_type_id: CapitalPlanActionType.find_by(class_name: 'AssetOverridePreparationCapitalPlanAction').id).update(completed_at: Time.now, completed_by_user_id: @user.id)
    end
  end

  def post_process
    # do nothing
    return true
  end

end