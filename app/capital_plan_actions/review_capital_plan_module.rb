class ReviewCapitalPlanModule < BaseCapitalPlanModule
  include TransamFormatHelper

  def complete
    plan = @capital_plan_module.capital_plan

    # soft delete all capital projects and ALIs
    projs = CapitalProject.where(organization_id: plan.organization_id, fy_year: plan.fy_year)
    alis = ActivityLineItem.where(capital_project_id: projs.ids)
    alis.update_all(active: false)
    projs.update_all(active: false)

    alis.each do |ali|
      # mark all assets as under replacement
      ali.assets.each do |asset|
        ReplacementStatusUpdateEvent.create(replacement_year: plan.fy_year, replacement_status_type_id: ReplacementStatusType.find_by(name: 'Underway').id, comments: "The #{format_as_fiscal_year(plan.fy_year)} capital plan includes the replacement of this asset.")
        asset.update_replacement_status
        asset.update_sogr
      end
    end

    # update archived fiscal year
    ArchivedFiscalYear.find_or_create_by(organization_id: plan.organization_id, fy_year: plan.fy_year)

  end
end