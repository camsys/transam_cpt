#------------------------------------------------------------------------------
#
# CapitalProjectBuilderJob
#
# Build SOGR projects
#
#------------------------------------------------------------------------------
class CapitalProjectBuilderJob < Job

  attr_accessor :organization
  attr_accessor :class_names
  attr_accessor :fta_asset_classes
  attr_accessor :start_fy
  attr_accessor :end_fy
  attr_accessor :creator

  def run

    # Run the builder
    options = {}
    options[:start_fy] = start_fy
    options[:end_fy] = end_fy

    assets = []
    class_names.each do |class_name|
      assets << class_name.constantize.replacement_by_policy
                    .where(fta_asset_class_id: fta_asset_classes, organization_id: organization.id, disposition_date: nil, scheduled_disposition_year: nil)
                    .where('transam_assets.scheduled_replacement_year >= ?', start_fy)

      assets << class_name.constantize.replacement_underway.where(fta_asset_class_id: fta_asset_classes, organization_id: organization.id)
    end
    options[:assets] = assets.flatten

    builder = CapitalProjectBuilder.new
    num_created = builder.build(organization, options)

    # Let the user know the results
    if num_created > 0
      msg = "SOGR Capital Project Analyzer completed. #{num_created} SOGR capital projects were added to #{organization.short_name}'s capital needs list."
      # Add a row into the activity table
      ActivityLog.create({:organization_id => organization.id, :user_id => creator.id, :item_type => "CapitalProjectBuilder", :activity => msg, :activity_time => Time.now})
    else
      msg = "No capital projects were created. #{organization.short_name} has #{CapitalProject.where(organization_id: organization.id).count} existing projects."
    end

    event_url = Rails.application.routes.url_helpers.capital_projects_path
    builder_notification = Notification.create(text: msg, link: event_url, notifiable_type: 'Organization', notifiable_id: organization.id)
    UserNotification.create(user: creator, notification: builder_notification)

  end

  def prepare
    Rails.logger.debug "Executing CapitalProjectBuilderJob at #{Time.now.to_s} for SOGR projects"
  end

  def check
    raise ArgumentError, "organization can't be blank " if organization.nil?
    raise ArgumentError, "class_names can't be blank " if class_names.nil?
    raise ArgumentError, "fta_asset_classes can't be blank " if fta_asset_classes.nil?
    raise ArgumentError, "start_fy can't be blank " if start_fy.nil?
    raise ArgumentError, "creator can't be blank " if creator.nil?
  end

  def initialize(organization, class_names, fta_asset_classes, start_fy, end_fy, creator)
    super
    self.organization = organization
    self.class_names = class_names
    self.fta_asset_classes = fta_asset_classes
    self.start_fy = start_fy
    self.end_fy = end_fy
    self.creator = creator
  end

end
