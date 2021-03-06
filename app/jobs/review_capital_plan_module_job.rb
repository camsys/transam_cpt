#------------------------------------------------------------------------------
#
# MoveAssetYearJob
#
# Uses the CapitalProjectBulider to move assets in ALIs from one FY to another updating its schedule
#
#------------------------------------------------------------------------------
class ReviewCapitalPlanModuleJob < Job

  include TransamFormatHelper

  attr_accessor :capital_plan_module

  def run

    plan = capital_plan_module.capital_plan

    # soft delete all capital projects and ALIs
    projs = CapitalProject.where(organization_id: plan.organization_id, fy_year: plan.fy_year)
    alis = ActivityLineItem.where(capital_project_id: projs.ids)
    alis.update_all(active: false)
    projs.update_all(active: false)

    alis.each do |ali|
      # mark all assets as under replacement
      ali.assets.each do |asset|
        ReplacementStatusUpdateEvent.create(transam_asset: asset, replacement_year: plan.fy_year, replacement_status_type_id: ReplacementStatusType.find_by(name: 'Underway').id, comments: "The #{format_as_fiscal_year(plan.fy_year)} capital plan includes the replacement of this asset.")

        # use try as new profiles don't have update_methods
        asset.try(:update_replacement_status)
        asset.try(:update_sogr)
      end
    end

    # update archived fiscal year
    ArchivedFiscalYear.find_or_create_by(organization_id: plan.organization_id, fy_year: plan.fy_year)

    event_url = Rails.application.routes.url_helpers.capital_plans_path
    notification = Notification.create!(text: "The #{format_as_fiscal_year(plan.fy_year)} Capital Plan has been archived for #{plan.organization.short_name}.", link: event_url, notifiable_type: 'Organization', notifiable_id: plan.organization_id)
    User.with_role(:admin).each do |usr|
      UserNotification.create!(user: usr, notification: notification)
    end

  end

  def prepare
    Rails.logger.debug "Executing ReviewCapitalPlanModuleJob at #{Time.now.to_s} for capital plans"
  end

  def check
    raise ArgumentError, "capital plan module can't be blank " if capital_plan_module.nil?
  end

  def initialize(capital_plan_module)
    super
    self.capital_plan_module = capital_plan_module
  end

end
