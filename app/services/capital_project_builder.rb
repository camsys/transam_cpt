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
  # Include the ali code mixin
  include AssetAliLookup

  # Instance vars
  attr_accessor :project_count

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------
  def build(organization, options = {})
    clear_all = options[:clear_all].blank? ? false : options[:clear_all]

    Rails.logger.info "#{self.class.name} Started at #{Time.now}."
    Rails.logger.info "Building Capital Projects for #{organization}."

    replacement_project_type = CapitalProjectType.find_by_code('R')
    rehabilitation_project_type = CapitalProjectType.find_by_code('I')
    
    if clear_all
      projects = CapitalProject.where('organization_id = ? AND capital_project_type_id IN (?)', organization, [replacement_project_type.id, rehabilitation_project_type.id])
      if projects.empty?
        Rails.logger.info "No SOGR projects found."
      else
        Rails.logger.info "Removing #{projects.count} exisiting SOGR projects."
        projects.each{|x| x.destroy}
      end
    end
    # Run the builder keeping track of how many projects were created
    @project_count = 0
    
    build_bottom_up(organization, options)
    
    # Return the number of projects created
    return @project_count
  end

  def build_bottom_up(organization, options)
        
    Rails.logger.debug "options = #{options.inspect}"
    create_tasks = options[:create_tasks].blank? ? true : options[:create_tasks]
    send_message = options[:send_message].blank? ? true : options[:send_message]

    Rails.logger.info "  Options: create_tasks = '#{create_tasks}', send_message = '#{send_message}'"
       
    # Cache some commonly used objects
    sys_user = User.find_by_first_name('system')
    high_priority = PriorityType.find_by_name('High')
    replacement_project_type = CapitalProjectType.find_by_code('R')
    rehabilitation_project_type = CapitalProjectType.find_by_code('I')
    
    #--------------------------------------------------------------------------------------
    # Basic Algorithm:
    #
    # Step 1: Loop through the list of possible scope codes for each fiscal year
    # Step 2: Get the list of available assets for this scope in this fiscal year.
    # Step 3: Build an ALI for each subcode (ALI) that has more than one available asset
    # Step 4: Add assets the the ALIs
    #
    #--------------------------------------------------------------------------------------
        
    # Get the current fiscal year and the last year that we will generate projects for
    start_year = current_fiscal_year_year
    last_year = last_fiscal_year_year
    
    Rails.logger.debug "start_year = #{start_year}, last_year  #{last_year}"
    
    # Only process road and rail assets for now

    # Find all the assets for this organization
    assets = Vehicle.where('organization_id = ? AND scheduled_disposition_date IS NULL', organization.id)  
    replace_scope = TeamAliCode.find_by_code('11.12.XX')
    rehab_scope = TeamAliCode.find_by_code('11.14.XX')

    # Busses. As some busses can be replaced within the planning horizon we 
    # add additional replacement projects for repalcing the replacements
    assets.each do |a|
      #-----------------------------
      # Process replacement projects
      #-----------------------------      
      year = a.scheduled_replacement_year
      unless year.nil? or year > last_year
        # Add the initial replacement 
        add_to_project(a, replace_scope, year, replacement_project_type)
        # See if this bus can be re-replaced within the planning time frame
        policy = a.policy
        max_service_life_years = policy.get_policy_item(a).max_service_life_years
        year += max_service_life_years
        Rails.logger.debug "Max Service Life = #{max_service_life_years} Next replacement = #{year}. Last year = #{last_year}"
        while year < last_year
          # Add a future re-replacement project for the asset
          add_to_project(a, replace_scope, year, replacement_project_type)
          year += max_service_life_years
        end 
      end
      #-----------------------------
      # Process rehabilitation projects
      #-----------------------------      
      year = a.scheduled_rehabilitation_year
      unless year.nil? or year > last_year
        add_to_project(a, rehab_scope, year, rehabilitation_project_type)
      end
    end
    
    # Rail Cars
    assets = RailCar.where('organization_id = ? AND scheduled_disposition_date IS NULL', organization.id)  
    replace_scope = TeamAliCode.find_by_code('12.12.XX')
    rehab_scope = TeamAliCode.find_by_code('12.14.XX')
    assets.each do |a|
      #-----------------------------
      # Process replacement projects
      #-----------------------------      
      year = a.scheduled_replacement_year
      unless year.nil? or year > last_year
        add_to_project(a, replace_scope, year, replacement_project_type) 
        # these assets are at least 25 year assets and will not be
        # replaced again within the planning timeframe
      end
      #-----------------------------
      # Process rehabilitation projects
      #-----------------------------      
      year = a.scheduled_rehabilitation_year
      unless year.nil? or year > last_year
        add_to_project(a, rehab_scope, year, rehabilitation_project_type)
      end
    end
    
    # Traction
    assets = Locomotive.where('organization_id = ? AND scheduled_disposition_date IS NULL', organization.id)  
    #replace_scope = TeamAliCode.find_by_code('12.12.XX')
    #rehab_scope = TeamAliCode.find_by_code('12.14.XX')
    assets.each do |a|
      #-----------------------------
      # Process replacement projects
      #-----------------------------      
      year = a.scheduled_replacement_year
      unless year.nil? or year > last_year
        add_to_project(a, replace_scope, year, replacement_project_type) 
      end
      #-----------------------------
      # Process rehabilitation projects
      #-----------------------------      
      year = a.scheduled_rehabilitation_year
      unless year.nil? or year > last_year
        add_to_project(a, rehab_scope, year, rehabilitation_project_type)
      end
    end

  end

  # Adds an asset to a SOGR project. If the project does not
  # exist it is created first.
  #
  def add_to_project(asset, scope, year, project_type)

    # Decode the scope so we can set the project up
    if scope.type == "11"
      focus = "Bus"  
    elsif scope.type == "12"
      focus = "Rail"  
    else
      focus = "Unknown"
    end

    if scope.category == "12"
      request = "replacement" 
      action = "Purchase"
    elsif scope.category == "14"
      request = "rehabilitation"  
      action = "Rehabilitate"
    else
      request = "unknown"
    end

    # See if there is an existing project for this scope and year
    project = CapitalProject.where('organization_id = ? AND team_ali_code_id = ? AND fy_year = ?', asset.organization.id, scope.id, year).first
    if project.nil?
      # create this project        
      project_title = "#{focus} #{request} project"          
      project = create_capital_project(asset.organization, year, scope, project_title, project_type)   
      project.save
      @project_count += 1
    end
    # See if there is an existing ALI for this asset
    team_ali_code = TeamAliCode.find_by_code("#{scope.type_and_category}.#{asset.asset_subtype.ali_code}")
    ali = ActivityLineItem.where('capital_project_id = ? AND team_ali_code_id = ?', project.id, team_ali_code.id).first
    # if there is an exisiting ALI, see if the asset is in it
    if ali
      unless ali.assets.exists?(asset)
        ali.assets << asset
      end
    else
      # Create the ALI and add it to the project
      ali_name = "#{action} #{team_ali_code.name} assets."
      ali = ActivityLineItem.new({:capital_project => project, :name => ali_name, :team_ali_code => team_ali_code})
      ali.save 
      
      # Now add the asset to it
      ali.assets << asset
    end
          
  end
  #
  # Main method. Options include
  #
  #   :create_tasks : true|false (true)
  #   :send_message : true|false (true)
  #
  def build_top_down(organization, options)
    
    Rails.logger.info "#{self.class.name} Started at #{Time.now}."
    Rails.logger.info "Building Capital Projects for #{organization}."
    
    Rails.logger.debug "options = #{options.inspect}"
    create_tasks = options[:create_tasks].blank? ? true : options[:create_tasks]
    send_message = options[:send_message].blank? ? true : options[:send_message]

    Rails.logger.info "  Options: create_tasks = '#{create_tasks}', send_message = '#{send_message}'"
       
    # Cache some commonly used objects
    sys_user = User.find_by_first_name('system')
    high_priority = PriorityType.find_by_name('High')
    replacement_project_type = CapitalProjectType.find_by_code('SRP')
    rehabilitation_project_type = CapitalProjectType.find_by_code('SRH')
    
    #--------------------------------------------------------------------------------------
    # Basic Algorithm:
    #
    # Step 1: Loop through the list of possible scope codes for each fiscal year
    # Step 2: Get the list of available assets for this scope in this fiscal year.
    # Step 3: Build an ALI for each subcode (ALI) that has more than one available asset
    # Step 4: Add assets the the ALIs
    #
    #--------------------------------------------------------------------------------------
        
    # Get the current fiscal year and the last year that we will generate projects for
    start_year = current_fiscal_year_year
    last_year = last_fiscal_year_year
    
    Rails.logger.debug "start_year = #{start_year}, last_year  #{last_year}"

    # Keep track of how many projects were created
    project_count = 0

    # This is the list of TEAM scopes that will be processed
    scope_codes = [
      "11.12.XX", # Bus Purchase Replacement
      '12.12.XX', # Rail Purchase Replacement
      '11.14.XX', # Bus Rebuild
      '12.14.XX'  # Rail Rebuild
      ]
        
    #
    # Step 1: Loop though each of the scope codes for each fiscal year and create a project
    #         if it does not already exist
    #
    scope_codes.each do |scope_code|
      scope = TeamAliCode.find_by_code(scope_code)

      # Decode the scope so we can set the project up
      if scope.type == "11"
        focus = "Bus"  
      elsif scope.type == "12"
        focus = "Rail"  
      else
        focus = "Unknown"
      end

      if scope.category == "12"
        request = "replacement" 
        action = "Purchase"
        project_type = replacement_project_type 
      elsif scope.category == "14"
        request = "rehabilitation"  
        action = "Rehabilitate"
        project_type = rehabilitation_project_type 
      else
        request = "unknown"
      end

      # Loop over each fiscal year
      (start_year..last_year).each do |year|
        Rails.logger.info "Processing scope #{scope} for FY #{year}"

        # See if there is an existing project for this org, this scope, and this year
        project = CapitalProject.where('organization_id = ? AND team_ali_code_id = ? AND fy_year = ?', organization.id, scope.id, replacement_project_type.id).first
        if project
          # Hmmm what to do here?
          Rails.logger.info "Project #{project.project_number} already exists. Skipping."
          next
        else          
          # Create a new project
          project_title = "#{focus} #{request} project"          
          project = create_capital_project(organization, year, scope, project_title, project_type)   
        end 
        
        # Step 2: Get the list of available assets for this project. The capital proejct can manage this
        #         as it knows what assets it can have associated with it
        assets = project.candidate_assets
        Rails.logger.debug "Found #{assets.count} assets"
        
        # If the asset list is empty we can move on to the next fiscal year
        if assets.empty?
          next
        else
          # save this project as there will be at least one ALI
          project.save
          project_count += 1
          Rails.logger.info "Created new Capital Project #{project.project_number}"

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
        end
        
        # Step 3: Build ALIs for each sub code for the scope
        scope.children.each do |ali|
          asset_subtypes = asset_subtypes_from_ali_code(ali.code)
          unless asset_subtypes.empty?
            # We found matching subtypes. See if we have any candidate assets that match
            subtype_ids = []
            asset_subtypes.each do |ast|
              subtype_ids << ast.id
            end
            # Do a subquery on the candidate list
            ali_assets = assets.where('asset_subtype_id IN (?)', subtype_ids)
            unless ali_assets.empty?
              # If we have candidates, go ahead and create an ALI
              Rails.logger.debug "Found #{ali_assets.count} assets for ALI #{ali.code}"
              
              # Create a new ALI
              ali_name = "#{action} #{ali_assets.count} #{focus} assets."
              ali = ActivityLineItem.new({:capital_project => project, :name => ali_name, :team_ali_code => ali})
              ali.save 
                           
              # Step 4: Add the assets to this ALI
              ali_assets.each do |a|
                ali.assets << a
              end
            end
          end
        end            
      end
    end
    
    # See if we need to send a message to every manager in this org indicating that new proejcts have been created
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
  
  def create_capital_project(org, fiscal_year, team_category, title, capital_project_type)

    puts "org = #{org}, fiscal_year = #{fiscal_year}, team_category = #{team_category}, title = #{title}, org = #{capital_project_type}"
    project = CapitalProject.new
    project.organization = org
    project.active = true
    project.emergency = false
    project.capital_project_status_type_id = 1
    project.fy_year = fiscal_year
    project.team_ali_code = team_category
    project.capital_project_type = capital_project_type
    project.title = title
    project.description = "Automatically generated by TransAM. Please provide a detailed description of this capital project."
    project.justification = "To be completed. Please provide a detailed justification for this capital project."
    #project.save
    
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