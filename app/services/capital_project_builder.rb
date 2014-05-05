#------------------------------------------------------------------------------
#
# CapitalProjectBuilder
#
# Analyzes an organizations's assets and generates a set of capital projects
# for the organization.
#
#------------------------------------------------------------------------------
class CapitalProjectBuilder
  
  # Include the fiscal year mixin
  include FiscalYear

  # Max number of years to analyze forward
  MAX_FORECASTING_YEARS = SystemConfig.instance.num_forecasting_years   

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  #
  # Main method. Options include
  #
  #   :type: replacement|rehabilitation|both (both)
  #   :create_tasks : true|false (true)
  #   :send_message : true|false (true)
  #
  def build(organization, options = {})
    
    Rails.logger.info "#{self.class.name} Started at #{Time.now}."
    Rails.logger.info "Building Capital Projects for #{organization}."
    
    Rails.logger.debug "options = #{options.inspect}"
    type = options[:type].blank? ? :both : options[:type]
    create_tasks = options[:create_tasks].blank? ? true : options[:create_tasks]
    send_message = options[:send_message].blank? ? true : options[:send_message]

    Rails.logger.info "  Options: type = '#{type}', create_tasks = '#{create_tasks}', send_message = '#{send_message}'"
       
    # Cache some commonly used objects
    sys_user = User.find_by_first_name('system')
    high_priority = PriorityType.find_by_name('High')
    
    # There are two main types for this implementation -- rehabilitation projects and
    # replacement projects -- we are not doing expansions yet
    
    # Algorithm -- for each FY, get the assets that are scheduled for replacement in that
    # fiscal year, if there are any that are not already in a capital project, create a new project
    # For each group of asset subtypes, create an activity line item and add the assets to the ALI
    # and add the ALI to the project.

    # Get the current fiscal year
    start_year = current_fiscal_year_year
    last_year = start_year + MAX_FORECASTING_YEARS
    
    Rails.logger.debug "start_year = #{start_year}, last_year  #{last_year}"

    # Keep track of how many projects were created
    project_count = 0
    
    # Loop over each asset type    
    asset_types = AssetType.all.each do |asset_type|
      Rails.logger.debug "Processing class = #{asset_type}"
      # Loop over each fiscal year
      (start_year..last_year).each do |year|
        # See how many assets are scheduled for replacement this FY taht are not already associated with a capital project
        assets = Asset.where('organization_id = ? AND asset_type_id = ? AND scheduled_replacement_year = ? AND id NOT IN (SELECT asset_id FROM activity_line_items_assets)', organization.id, asset_type.id, year)
                
        # If there are assets to program we create a new project
        if assets.count > 0
                    
          Rails.logger.debug "Found #{assets.count} assets for FY #{year}"
          # Create a new Capital Project
          category  = TeamCategory.find_by_code('12')       # Purchase/Replacement
          scope     = TeamScopeCode.find_by_code('111-00')  # Bus Rolling Stock
          title     = "Replacement of #{asset_type}s"          
          project = create_capital_project(organization, year, category, scope, title)
          
          # increment our counter
          project_count += 1
          
          Rails.logger.info "Created new Capital Project #{project.project_number}"
          
          # Create ALIs for each asset subtype in this FY
          asset_subtypes = AssetSubtype.where('asset_type_id = ?', asset_type.id)
          # Filter the asset list by this asset subtype
          asset_subtypes.each do |subtype|
            Rails.logger.debug "Processing subtype = #{subtype}"
            ali_assets = assets.where('asset_subtype_id = ?', subtype.id)
            # if we have some assets we create an ALI
            if ali_assets.count > 0
              Rails.logger.debug "Found #{ali_assets.count} assets for subtype #{subtype}"
              # Create a new ALI
              name = "Purchase #{ali_assets.count} replacement #{subtype}"
              sub_category = TeamSubCategory.find_by_name(subtype.name)
              ali = ActivityLineItem.new({:capital_project => project, :name => name, :team_sub_category => sub_category})
              ali.save              
              # Add the assets to this ALI
              ali_assets.each do |a|
                ali.assets << a
              end
            end
          end  # asset_subtypes
          
          if create_tasks
            # Generate a task for each manager to validate the project we just created
            managers = Role.find_by_name('manager').users.where('organization_id = ?', 1)
            managers.each do |manager|
              task = Task.new
              task.from_user = sys_user
              task.from_organization = sys_user.organization
              task.priority_type = high_priority
              task.for_organization = organization
              task.assigned_to = manager
              task.subject = "Complete new capital project #{project.project_number}."
              task.body = "Capital Project #{project.project_number} has been created. You need to open this project and complete the following items. If you have any questions call XXX and yyy."
              task.complete_by = Date.today + 1.month
              task.send_reminder = true
              task.save
              
              Rails.logger.debug "Task #{task.object_key} has been created."
            end
          end
        end #create project        
      end
    end   
    # See if we need to send a message toe very manager in this org indicating that new proejcts have been created
    if project_count > 0 && send_message
      managers = Role.find_by_name('manager').users.where('organization_id = ?', 1)
      managers.each do |manager|
        msg = Message.new
        msg.organization = organization
        msg.user = sys_user
        msg.to_user = manager
        msg.priority_type = high_priority
        msg.subject = "New capital projects have been created."
        msg.body = "#{project_count} new capital projects have been added to the capital needs list for your organization."
        msg.save
        Rails.logger.debug "Message #{msg.object_key} has been created."
      end
    end

    Rails.logger.info "#{self.class.name} completed at #{Time.now}."
    # return the number of projects created
    project_count
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected
  
  def create_capital_project(org, fiscal_year, category, scope, title)

    project = CapitalProject.new
    project.organization = org
    project.active = true
    project.emergency = false
    project.capital_project_status_type_id = 1
    project.fy_year = fiscal_year
    project.team_category = category
    project.team_scope_code = scope
    project.title = title
    project.description = "Automatically generated by TransAM. Please provide a detailed description of this capital project."
    project.justification = "To be completed. Please provide a detailed justificaiton for this capital project."
    project.save
    
    # return it
    project    
  end
  #------------------------------------------------------------------------------
  #
  # Private Methods
  #
  #------------------------------------------------------------------------------
  private
  
end