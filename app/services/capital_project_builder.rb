#-------------------------------------------------------------------------------
#
# CapitalProjectBuilder
#
# Analyzes an organizations's assets and generates a set of capital projects
# for the organization.
#
#-------------------------------------------------------------------------------
class CapitalProjectBuilder

  # Include the fiscal year mixin
  include FiscalYear

  # Instance vars
  attr_reader :project_count
  attr_reader :replacement_project_type
  attr_reader :rehabilitation_project_type
  attr_reader :start_year
  attr_reader :last_year

  #-----------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #-----------------------------------------------------------------------------

  # Returns the set of asset types for an organization that are eligible for
  # SOGR building
  def eligible_asset_types(org)
    # Select the asset types that they are allowed to build. This is narrowed down to only
    # asset types they own and those which are fta vehicles
    asset_types = []
    org.asset_type_counts.each do |type, count|
      asset_type = AssetType.find(type)
      if ['Vehicle', 'SupportVehicle', 'RailCar', 'Locomotive', 'Equipment'].include? asset_type.class_name
        asset_types << asset_type
      end
    end
    asset_types
  end

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

    # Make sure the asset is strongly typed
    a = asset.is_typed? ? asset : Asset.get_typed_asset(asset)

    # Run the update
    process_asset(a, @start_year, @last_year, @replacement_project_type, @rehabilitation_project_type)

  end

  # Update an activity line item and all of its assets to a new planning year
  # Note what process_asset actually does is create a new ALI
  def move_ali_to_planning_year(ali, fy_year)
    unless ali
      Rails.logger.error "Nil ALI"
      return nil
    end

    cp = ali.capital_project
    assets = ali.assets.collect{|a| Asset.get_typed_asset(a)}

    projects_and_alis = assets.collect do |asset|
      move_asset(asset, fy_year, ali)
    end

    # The ALI should now be empty, and so we remove it because we "moved" it
    ali.reload
    unless ali.assets.empty?
      ali.assets.each do |a|
        Rails.logger.info a.ai
      end
      raise "assertion failed, ALI is not empty: #{ali}"
    end
    ali.destroy

    # Check if the ALI's capital project is now empty, and if so, destroy it
    cp.reload
    cp.destroy if cp.activity_line_items.empty?

    projects_and_alis
  end

  # Set resonable defaults for the builder
  def initialize
    # These are hashes for caching scopes so we don't have to look them up all the time
    @replace_subtype_scope_cache = {}
    @rehab_subtype_scope_cache = {}

    # Keep track of how many projects were created
    @project_count = 0

    # Get the current fiscal year and the last year that we will generate projects for. We can only generate projects for planning years
    # Year 1, Year 2,..., Year 12
    @start_year = current_planning_year_year
    @last_year = last_fiscal_year_year

    @replacement_project_type = CapitalProjectType.find_by_code('R')
    @rehabilitation_project_type = CapitalProjectType.find_by_code('I')

  end

  #-----------------------------------------------------------------------------
  # Protected Methods
  #-----------------------------------------------------------------------------
  protected

  def build_bottom_up(organization, options)

    Rails.logger.debug "options = #{options.inspect}"

    # Get the options. There must be at least one type of asset to process
    asset_type_ids = options[:asset_type_ids]
    if asset_type_ids.blank?
      asset_type_ids = []
      eligible_asset_types(organization).each{|x| asset_type_ids << x.id}
    end
    # User must set the start fy year as well otherwise we use the first planning year
    if options[:start_fy].to_i > 0
      @start_year = options[:start_fy].to_i
    end

    create_tasks = options[:create_tasks].blank? ? true : options[:create_tasks]
    send_message = options[:send_message].blank? ? true : options[:send_message]

    Rails.logger.info "  Options: create_tasks = '#{create_tasks}', send_message = '#{send_message}'"

    # Cache the list of eligible asset types for this organization
    org_asset_types = eligible_asset_types(organization)
    Rails.logger.debug "  Eligible asset types = org_asset_types.inspect"

    #---------------------------------------------------------------------------
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
    #---------------------------------------------------------------------------

    # Get the current fiscal year and the last year that we will generate projects for. We can only generate projects
    # for planning years Year 1, Year 2,..., Year 12
    # @start_year = current fiscal year
    # @last_year = last year that we will generate projects for

    Rails.logger.info  "start_year = #{@start_year}, last_year  #{@last_year}"
    Rails.logger.debug "start_year = #{@start_year}, last_year  #{@last_year}"

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

      # Filter out anything that is not eleigible for building
      unless org_asset_types.include? asset_type
        Rails.logger.info "Can't process asset type #{asset_type}."
        next
      end

      # Find all the matching assets for this organization. This logic returns a strongly typed set of assets
      klass = asset_type.class_name.constantize
      assets = klass.where('organization_id = ? AND disposition_date IS NULL AND scheduled_disposition_year IS NULL', organization.id)

      # Process each asset in turn...
      assets.each do |a|
        # do the work...
        process_asset(a, @start_year, @last_year, @replacement_project_type, @rehabilitation_project_type)
      end

      # Get the next asset type id
    end

  end

  #-----------------------------------------------------------------------------
  # Process a single asset adding it to replacement and rehabilitation projects as
  # needed. Projects are created if they fon't already exists otherwise the
  # asset is added to existing projects
  #-----------------------------------------------------------------------------
  def process_asset(asset, start_year, last_year, replacement_project_type, rehabilitation_project_type, target_year=nil, current_ali=nil)

    Rails.logger.info "Processing asset #{asset.object_key}, start_year = #{start_year}, last_year = #{last_year}, #{replacement_project_type}, #{rehabilitation_project_type}, target_year=#{target_year}"

    projects_and_alis = []

    # Remove the asset from any existing ALIs, or the specified one
    if current_ali.nil?
      asset.activity_line_items.each do |ali|
        Rails.logger.debug "deleting asset #{asset.object_key} from ALI #{ali.object_key}"
        ali.assets.delete asset
      end
    else
      Rails.logger.debug "deleting asset #{asset.object_key} from ALI #{current_ali.object_key}"
      current_ali.assets.delete asset
    end

    # Can't build projects for assets that have been scheduled for disposition or already disposed
    if asset.disposed? or asset.scheduled_for_disposition?
      Rails.logger.info "Asset #{asset.object_key} has been scheduled for disposition. Nothing to do."
      return
    end

    #---------------------------------------------------------------------------
    # Step 1: Data consistency check
    #---------------------------------------------------------------------------
    asset_data_consistency_check(asset, start_year)

    #---------------------------------------------------------------------------
    # Step 2: Process initial rehabilitation (this happens here only if
    # the initial rehab happens before the initial replacement)
    #---------------------------------------------------------------------------

    # Get the policy analyzer for this asset
    policy_analyzer = asset.policy_analyzer

    # Get the replacment and rehab ALI codes for this asset. If the policy rule
    # specifies leased we need the lease
    if policy_analyzer.get_replace_with_leased
      replace_ali_code = TeamAliCode.find_by(:code => policy_analyzer.get_lease_replacement_code)
    else
      replace_ali_code = TeamAliCode.find_by(:code => policy_analyzer.get_purchase_replacement_code)
    end
    rehab_ali_code = TeamAliCode.find_by(:code => policy_analyzer.get_rehabilitation_code)

    # See if the policy requires scheduling rehabilitations.
    rehab_month = asset.policy_analyzer.get_rehabilitation_service_month.to_i
    process_rehabs = (rehab_month.to_i > 0)

    # If the asset has already been scheduled for a rehab, add this to the plan
    if asset.scheduled_rehabilitation_year.present?
      projects_and_alis << add_to_project(asset, rehab_ali_code, asset.scheduled_rehabilitation_year, rehabilitation_project_type)
    end

    # Initial replacement
    year = asset.scheduled_replacement_year
    min_service_life_years = asset.policy_analyzer.get_min_service_life_months / 12

    unless year < start_year or year > last_year

      #-------------------------------------------------------------------------
      # Step 3: Process initial replacement and rehab
      #-------------------------------------------------------------------------
      # Add the initial replacement. If the project does not exist it is created
      projects_and_alis << add_to_project(asset, replace_ali_code, year, replacement_project_type)

      if process_rehabs
        rehab_year = year + (rehab_month / 12)
        if rehab_year <= last_year
          projects_and_alis << add_to_project(asset, rehab_ali_code, rehab_year, rehabilitation_project_type)
        end
      end

      #-------------------------------------------------------------------------
      # Step 4: Process replacements
      #-------------------------------------------------------------------------
      year += min_service_life_years
      Rails.logger.debug "Max Service Life = #{min_service_life_years} Next replacement = #{year}. Last year = #{last_year}"

      while year < last_year
        # Add a future re-replacement project for the asset
        projects_and_alis << add_to_project(asset, replace_ali_code, year, replacement_project_type)

        if process_rehabs
          rehab_year = year + (rehab_month / 12)
          if rehab_year <= last_year
            projects_and_alis << add_to_project(asset, rehab_ali_code, rehab_year, rehabilitation_project_type)
          end
        end

        year += min_service_life_years
      end
    end

    projects_and_alis
  end

  #-----------------------------------------------------------------------------
  # Data consistency check
  #
  # Make sure that the asset has a in service date and a scheduled replacement year.
  # If the scheduled replacement year is not set, default it to the policy replacement year
  # or the first planning year if the asset is in backlog
  #
  # start year is the first planning year
  #
  #-----------------------------------------------------------------------------
  def asset_data_consistency_check(asset, start_year)

    if asset.in_service_date.nil?
      asset.in_service_date = asset.purchase_date
    end

    # Ensure that the asset has a valid policy replacement year
    if asset.policy_replacement_year.blank?
      asset.policy_replacement_year = asset.calculate_replacement_year
    end

    # Set the schedule replacement year to the policy year if it is not already
    # set
    if asset.scheduled_replacement_year.nil?
      asset.scheduled_replacement_year = asset.policy_replacement_year
    end

    # Take care of backlogged assets. Any asset in backlog will be scheduled for
    # replacement in the first planning year
    if asset.policy_replacement_year < start_year
      asset.scheduled_replacement_year = start_year
    end

    # Check to see if the asset has a scheduled rehabilitation year and if so
    # make sure it is rational ie. must be before the replacement year
    if asset.scheduled_rehabilitation_year.present?
      # is it scheduled in the replacement year
      if asset.scheduled_rehabilitation_year == asset.scheduled_replacement_year
        # Clear the rehab year and let the system recalculate it as needed
        asset.scheduled_rehabilitation_year = nil
      elsif asset.scheduled_rehabilitation_year < start_year
        # it is scheduled before the start year so it is in backlog
        asset.scheduled_rehabilitation_year = start_year
      end
    end

    # Check to see if the policy requries replacing with new or used assets
    if asset.scheduled_replace_with_new.blank?
      asset.scheduled_replace_with_new = asset.policy_analyzer.get_replace_with_new
    end

    # See if the asset has any scheduled replacement or rehabilitation costs, if not
    # use the estimated costs
    if asset.scheduled_replacement_cost.blank?
      Rails.logger.debug "asset scheduled_replacement_cost is blank, setting to est: #{asset.estimated_replacement_cost}"
      asset.scheduled_replacement_cost = asset.estimated_replacement_cost
    end

    if asset.changed?
      asset.save(:validate => false)
    end

  end

  #-----------------------------------------------------------------------------
  # Adds an asset to a SOGR project. If the project does not
  # exist it is created first,
  #-----------------------------------------------------------------------------
  def add_to_project(asset, ali_code, year, project_type)

    Rails.logger.debug "add_to_project: asset=#{asset.object_key} ali_code=#{ali_code} year=#{year} project_type=#{project_type}"
    # The ALI project scope is the parent of the ali code so if the ALI code is 11.11.01 (replace 40 ft bus)
    # the scope becomes 11.11.XX (bus replacement project)
    scope = ali_code.parent

    # Decode the scope so we can set the project up
    if scope.type == "11"
      focus = "Bus"
    elsif scope.type == "12"
      focus = "Rail"
    else
      focus = "Unknown"
    end

    if scope.category[0] == "4"
      focus = "#{focus} support vehicles"
    end

    if ["2"].include? scope.category[1]
      request = "replacement"
      action = "Purchase"
    elsif ["6"].include? scope.category[1]
      request = "replacement"
      action = "Lease"
    elsif ["4"].include? scope.category[1]
      request = "rehabilitation"
      action = "Rehabilitate"
    elsif ["5"].include? scope.category[1]
      request = "mid-life rebuild"
      action = "Rebuild"
    elsif ["7"].include? scope.category[1]
      request = "vehicle overhaul"
      action = "Overhaul"
    else
      request = "unknown"
    end

    # See if there is an existing project for this scope and year
    project = CapitalProject.find_by('organization_id = ? AND team_ali_code_id = ? AND fy_year = ?', asset.organization.id, scope.id, year)
    if project.nil?
      # create this project
      project_title = "#{focus} #{request} project"
      project = create_capital_project(asset.organization, year, scope, project_title, project_type)
      @project_count += 1
      Rails.logger.debug "Created new project #{project.object_key}"
    else
      Rails.logger.debug "Using existing project #{project.object_key}"
    end
    ali = ActivityLineItem.find_by('capital_project_id = ? AND team_ali_code_id = ?', project.id, ali_code.id)
    # if there is an exisiting ALI, see if the asset is in it
    if ali
      Rails.logger.debug "Using existing ALI #{ali.object_key}"
      unless ali.assets.exists?(asset)
        Rails.logger.debug "asset not in ALI, adding it"
        ali.assets << asset
      else
        Rails.logger.debug "asset already in ALI, not adding it"
      end
    else
      # Create the ALI and add it to the project
      ali_name = "#{action} #{ali_code.name} assets."
      ali = ActivityLineItem.new({:capital_project => project, :name => ali_name, :team_ali_code => ali_code})
      ali.save

      # Now add the asset to it
      ali.assets << asset
      Rails.logger.debug "Created new ALI #{ali.object_key}"
    end

    [project, ali]
  end

  #-----------------------------------------------------------------------------
  # Creates a new capital project
  #-----------------------------------------------------------------------------
  def create_capital_project(org, fiscal_year, ali_code, title, capital_project_type)

    project = CapitalProject.new
    project.organization = org
    project.active = true
    project.sogr = true
    project.multi_year = false
    project.emergency = false
    project.fy_year = fiscal_year
    project.team_ali_code = ali_code
    project.capital_project_type = capital_project_type
    project.title = title
    project.description = "Automatically generated by TransAM. Please provide a detailed description of this capital project."
    project.justification = "To be completed. Please provide a detailed justification for this capital project."
    project.save
    project
  end

  #-----------------------------------------------------------------------------
  #
  # Private Methods
  #
  #-----------------------------------------------------------------------------
  private

end
