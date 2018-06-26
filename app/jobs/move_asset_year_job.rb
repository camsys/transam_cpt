#------------------------------------------------------------------------------
#
# MoveAssetYearJob
#
# Uses the CapitalProjectBulider to move assets in ALIs from one FY to another updating its schedule
#
#------------------------------------------------------------------------------
class MoveAssetYearJob < Job

  # Include the fiscal year mixin
  include FiscalYear

  attr_accessor :activity_line_item
  attr_accessor :fy_year
  attr_accessor :targets
  attr_accessor :creator
  attr_accessor :early_replacement_reason

  def run

    service = CapitalProjectBuilder.new
    assets = activity_line_item.assets.where(:object_key => targets.split(','))
    assets_count = assets.count
    Rails.logger.debug "Found #{assets_count} assets to process"
    assets.each do |a|
      # Replace or Rehab?
      if activity_line_item.rehabilitation_ali?
        a.scheduled_rehabilitation_year = fy_year
      else
        a.scheduled_replacement_year = fy_year
        a.update_early_replacement_reason(early_replacement_reason)
      end

      a.save(:validate => false)
      a.reload
      service.update_asset_schedule(a)
      a.reload

      # update the original ALI's estimated cost for its assets
      updated_ali = ActivityLineItem.find_by(id: activity_line_item.id)
      if updated_ali.present?
        updated_ali.update_estimated_cost
        Rails.logger.debug("NEW COST::: #{updated_ali.estimated_cost}")
      end

    end

    # Add a row into the activity table
    ActivityLog.create({:organization_id => activity_line_item.capital_project.organization.id, :user_id => creator.id, :item_type => "CapitalProjectBuilder", :activity => "Moved #{assets_count} assets in #{activity_line_item} to #{fiscal_year(fy_year)}", :activity_time => Time.now})

    event_url = Rails.application.routes.url_helpers.planning_index_path
    move_assets_notification = Notification.create!(text: "Moved #{assets_count} assets to #{fiscal_year(fy_year)}. Click here to see the updated Project Planner.", link: event_url, notifiable_type: 'Organization', notifiable_id: activity_line_item.capital_project.organization_id)
    UserNotification.create!(user: creator, notification: move_assets_notification)

  end

  def prepare
    Rails.logger.debug "Executing MoveAssetYearJob at #{Time.now.to_s} for SOGR projects"
  end

  def check
    raise ArgumentError, "activity_line_item can't be blank " if activity_line_item.nil?
    raise ArgumentError, "fy_year can't be blank " if fy_year.nil?
    raise ArgumentError, "targets can't be blank " if targets.nil?
    raise ArgumentError, "creator can't be blank " if creator.nil?
  end

  def initialize(activity_line_item, fy_year, targets, creator, early_replacement_reason)
    super
    self.activity_line_item = activity_line_item
    self.fy_year = fy_year
    self.targets = targets
    self.creator = creator
    self.early_replacement_reason = early_replacement_reason
  end

end
