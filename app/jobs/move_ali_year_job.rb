#------------------------------------------------------------------------------
#
# MoveAliYearJob
#
#------------------------------------------------------------------------------
class MoveAliYearJob < Job

  # Include the fiscal year mixin
  include FiscalYear

  attr_accessor :activity_line_item
  attr_accessor :fy_year
  attr_accessor :creator
  attr_accessor :early_replacement_reason

  def run

    Rails.logger.debug "Moving ali #{activity_line_item} to new FY #{fy_year}"
    CapitalProjectBuilder.new.move_ali_to_planning_year(activity_line_item, fy_year, early_replacement_reason)

    event_url = Rails.application.routes.url_helpers.planning_index_path
    move_ali_notification = Notification.create!(text: "The ALI #{activity_line_item.name} (#{activity_line_item.team_ali_code}) was successfully moved to #{fy_year}.", link: event_url, notifiable_type: 'ActivityLineItem', notifiable_id: activity_line_item.id)
    UserNotification.create!(user: creator, notification: move_ali_notification)

  end

  def prepare
    Rails.logger.debug "Executing MoveAliYearJob at #{Time.now.to_s} for SOGR projects"
  end

  def check
    raise ArgumentError, "activity_line_item can't be blank " if activity_line_item.nil?
    raise ArgumentError, "fy_year can't be blank " if fy_year.nil?
    raise ArgumentError, "creator can't be blank " if creator.nil?
  end

  def initialize(activity_line_item, fy_year, creator, early_replacement_reason)
    super
    self.activity_line_item = activity_line_item
    self.fy_year = fy_year
    self.creator = creator
    self.early_replacement_reason = early_replacement_reason
  end

end
