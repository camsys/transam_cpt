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
  
  # Main entry point for the builder. This invokes the bottom-up builder
  def build(organization, options = {})
        
    Rails.logger.info "#{self.class.name} Started at #{Time.now}."
    Rails.logger.info "Building Capital Projects for #{organization}."
    
    build_bottom_up(organization, options)
    
    # Return the number of projects created
    return @project_count
  end

  # Schedules replacement and rehabilitation projects for an individual asset
  def update_asset_schedule(asset)
        
    replacement_project_type = CapitalProjectType.find_by_code('R')
    rehabilitation_project_type = CapitalProjectType.find_by_code('I')

    # Make sure the asset is strongly typed    
    a = asset.is_typed? ? asset : Asset.get_typed_asset(asset)
    
    # Run the update
    process_asset(a, @start_year, @last_year, replacement_project_type, rehabilitation_project_type)
          
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  def build_bottom_up(organization, options)
        
    Rails.logger.debug "options = #{options.inspect}"
    
    # Get the options. There must be at least one type of asset to process
    asset_type_ids = options[:asset_type_ids]
        
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
    # For each selected asset type...
    #   For each asset that is not disposed or marked for disposition...
    #
    #     Step 1: Make sure that it has a scheduled replacement year and in_seervice_date.
    #             Update the asset if these are not set
    #     Step 2: if the scheduled replacement year is before the first planning year or after the last
    #             planning year there is nothing to do so skip to Step 5
    #     Step 3: Check to see if a replacement project exists and create it if it does not. Add
    #             the asset to the replacement project
    #     Step 4: Get the policy and see if the replacement can be replaced within the planning time frame
    #             Add new projects for each replacement cycle
    #     Step 5: Check to see if the asset has a rehabilitation year set. If so create a rehabilitation
    #             project if one does not exist or add to it if it does exist.
    #
    #--------------------------------------------------------------------------------------
        
    # Get the current fiscal year and the last year that we will generate projects for. We can only generate projects 
    # for planning years Year 1, Year 2,..., Year 12
    start_year = @start_year
    last_year = @last_year
    
    Rails.logger.debug "start_year = #{start_year}, last_year  #{last_year}"
        
    # Loop through the list of asset type ids
    asset_type_ids.each do |asset_type_id|

      if asset_type_id.blank?
        next
      end
      
      asset_type = AssetType.find(asset_type_id)   
      if asset_type.nil?
        Rails.logger.info "Can't process asset type where id = #{asset_type_id}"
        next
      end

      # Filter out anything but rolling stock for now
      unless [1,2,3,7].include? asset_type.id
        Rails.logger.info "Can't process asset type where id = #{asset_type_id}. System only works for Vehicles, Rail Cars, Locomotives, and Support Vehicles"
        next
      end
               
      # Find all the matching assets for this organization. This logic returns a strongly typed set of assets
      klass = asset_type.class_name.constantize
      assets = klass.where('organization_id = ? AND disposition_date IS NULL AND scheduled_disposition_year IS NULL', organization.id)  

      # Process each asset in turn...
      assets.each do |a|
        # do the work...
        process_asset(a, start_year, last_year, replacement_project_type, rehabilitation_project_type)      
      end

      # Get the next asset type id
    end    
    
  end
  
  # actually process an asset
  def process_asset(asset, start_year, last_year, replacement_project_type, rehabilitation_project_type)
    
    # Remove the asset from any existing capital projects
    asset.activity_line_items.each do |ali|
      ali.assets.delete asset
    end
    
    # Can't build projects for assets that have been scheduled for disposition or already disposed
    if asset.disposition_date or asset.scheduled_disposition_year
      return
    end
    
    #-----------------------------
    # Step 1: Data consistency check
    #
    # Make sure that the asset has a in service date and a scheduled replacement year. 
    # If the scheduled replacement year is not set, default it to the policy replacement year 
    # or the first planning year if the asset is in backlog
    #
    #-----------------------------
    changed = false
    if asset.in_service_date.nil?
      asset.in_service_date = asset.purchase_date
      changed = true
    end
    if asset.scheduled_replacement_year.nil?
      if asset.policy_replacement_year < start_year
        asset.scheduled_replacement_year = start_year
      else
        asset.scheduled_replacement_year = asset.policy_replacement_year
      end
      changed = true
    end
    if changed
      asset.save
    end
    
    #-----------------------------
    # Step 2: Filter replacements that are outside of the planning time frame
    #
    # Make sure that the asset has a scheduled replacement year. If it is not set
    # default it to the policy replacement year or the first planning year if the asset
    # is in backlog
    #-----------------------------
    year = asset.scheduled_replacement_year
    unless year < start_year or year > last_year

      #-----------------------------
      # Step 3: Process initial replacement
      #-----------------------------      

      # get the replacement scope for this asset
      replace_scope = get_replace_scope(asset)
      # Add the initial replacement. If the project does not exist it is created
      add_to_project(asset, replace_scope, year, replacement_project_type)

      #-----------------------------
      # Step 4: Process initial replacement
      #
      # See if the replacement can be replaced within the planning time frame
      #-----------------------------                
      max_service_life_years = asset.policy_rule.max_service_life_years
      year += max_service_life_years
      Rails.logger.debug "Max Service Life = #{max_service_life_years} Next replacement = #{year}. Last year = #{last_year}"

      while year < last_year
        # Add a future re-replacement project for the asset
        add_to_project(asset, replace_scope, year, replacement_project_type)
        year += max_service_life_years
      end 
    end
    #-----------------------------
    # Step 5: Process rehabilitation projects
    #-----------------------------      
    year = asset.scheduled_rehabilitation_year.nil? ? 9999 : asset.scheduled_rehabilitation_year
    unless year < start_year or year > last_year
      # get the rehab scope for this asset
      rehab_scope = get_rehab_scope(asset)
      # This will create the project if it does not exist
      add_to_project(asset, rehab_scope, year, rehabilitation_project_type)
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

    if scope.category[1] == "2"
      request = "replacement" 
      action = "Purchase"
    elsif scope.category[1] == "6"
      request = "replacement" 
      action = "Lease"
    elsif scope.category[1] == "4"
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

  
  def get_replace_scope(asset)
    
    # See if we have already cached this scope. If not, get it and cache it
    if @replace_subtype_scope_cache[asset.asset_subtype_id].nil?
      # Get the replacement ALI code from the policy      
      ali_code = asset.policy_rule.replacement_ali_code
      # check to see that one was set of default otherwise
      if ali_code.blank?
        if asset.type_of? :vehicle
          ali_code = '11.12.XX'
        elsif asset.type_of? :rail_car or asset.type_of? :locomotive
          ali_code = '12.12.XX'
        elsif asset.type_of? :support_vehicle
          ali_code = '11.42.XX'
        end
      end
      @replace_subtype_scope_cache[asset.asset_subtype_id] = TeamAliCode.find_by_code(ali_code)
    end
    # Return the cached version
    @replace_subtype_scope_cache[asset.asset_subtype_id]
  end

  def get_rehab_scope(asset)
    # See if we have already cached this scope. If not, get it and cache it
    if @rehab_subtype_scope_cache[asset.asset_subtype_id].nil?
      # Get the rehabilitation ALI code from the policy      
      ali_code = asset.policy_rule.rehabilitation_ali_code
      # check to see that one was set of default otherwise
      if ali_code.blank?
        if asset.type_of? :vehicle
          ali_code = "11.14.XX"
        elsif asset.type_of? :rail_car or asset.type_of? :locomotive
          ali_code = "12.14.XX"
        elsif asset.type_of? :support_vehicle 
          ali_code = "11.44.XX"
        end
      end
      @rehab_subtype_scope_cache[asset.asset_subtype_id] = TeamAliCode.find_by_code(ali_code)
    end
    # Return the cached version
    @rehab_subtype_scope_cache[asset.asset_subtype_id]    
  end

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

  # Set resonable defaults for the builder
  def initialize
    
    # These are hashes for caching scopes so we don't have to look them up all the time
    @replace_subtype_scope_cache = {}
    @rehab_subtype_scope_cache = {}
    
    # Keep track of how many projects were created
    @project_count = 0

    # Get the current fiscal year and the last year that we will generate projects for. We can only generate projects for planning years
    # Year 1, Year 2,..., Year 12
    @start_year = current_fiscal_year_year + 1
    @last_year = last_fiscal_year_year

  end    
  
end