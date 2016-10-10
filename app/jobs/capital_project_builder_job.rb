#------------------------------------------------------------------------------
#
# CapitalProjectBuilderJob
#
# Build SOGR projects
#
#------------------------------------------------------------------------------
class CapitalProjectBuilderJob < Job

  attr_accessor :organization
  attr_accessor :asset_types
  attr_accessor :start_fy
  attr_accessor :creator

  def run

    # Run the builder
    options = {}
    options[:asset_type_ids] = asset_types
    options[:start_fy] = start_fy
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
    raise ArgumentError, "asset_types can't be blank " if asset_types.nil?
    raise ArgumentError, "start_fy can't be blank " if start_fy.nil?
    raise ArgumentError, "creator can't be blank " if creator.nil?
  end

  def initialize(organization, asset_types, start_fy, creator)
    super
    self.organization = organization
    self.asset_types = asset_types
    self.start_fy = start_fy
    self.creator = creator
  end

end
