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

  # Instance vars
  attr_accessor :project_count, :replacement_project_type, :rehabilitation_project_type

  def initialize
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # Returns the set of asset types for an organization that are eligible for
  # SOGR building
  def eligible_asset_types(org)
    # Select the asset types that they are allowed to build. This is narrowed down to only
    # asset types they own and those which are fta vehicles
    asset_types = []
    org.asset_type_counts.each do |type, count|
      asset_type = AssetType.find(type)
      if ['Vehicle', 'SupportVehicle', 'RailCar', 'Locomotive'].include? asset_type.class_name
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

    # Cache the list of eligible asset types for this organization
    org_asset_types = eligible_asset_types(organization)
    Rails.logger.debug "  Eligible asset types = org_asset_types.inspect"

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

  # actually process an asset
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
    if asset.disposition_date or asset.scheduled_disposition_year
      Rails.logger.info "Asset #{asset.object_key} has been scheduled for disposition. Nothing to do."
      return
    end

    #-----------------------------
    # Step 1: Data consistency check
    #-----------------------------
    asset_data_consistency_check(asset, target_year, start_year)

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

      # get the replacement ALI code for this asset
      replace_ali_code = get_replace_ali_code(asset)
      # Add the initial replacement. If the project does not exist it is created
      projects_and_alis << add_to_project(asset, replace_ali_code, year, replacement_project_type)

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
        projects_and_alis << add_to_project(asset, replace_ali_code, year, replacement_project_type)
        year += max_service_life_years
      end
    end
    #-----------------------------
    # Step 5: Process rehabilitation projects
    #-----------------------------
    year = asset.scheduled_rehabilitation_year.nil? ? 9999 : asset.scheduled_rehabilitation_year
    unless year < start_year or year > last_year
      # get the rehab scope for this asset
      rehab_ali_code = get_rehab_ali_code(asset)
      # This will create the project if it does not exist
      projects_and_alis << add_to_project(asset, rehab_ali_code, year, rehabilitation_project_type)
    end

    projects_and_alis
  end

  # move an asset
  def move_asset(asset, target_year, current_ali)

    Rails.logger.info "Moving asset #{asset.object_key}, target_year=#{target_year}, current_ali=#{current_ali.object_key}"

    projects_and_alis = []

    # Can't build projects for assets that have been scheduled for disposition or already disposed
    if asset.disposition_date or asset.scheduled_disposition_year
      msg =  "Asset #{asset.object_key} has been scheduled for disposition. Not processing it."
      Rails.logger.warning msg
      raise msg
    end

    current_project = current_ali.capital_project
    ali_code = current_ali.team_ali_code

    # Remove the asset from the specified ALI
    Rails.logger.debug "deleting asset #{asset.object_key} from ALI #{current_ali.object_key}"
    current_ali.assets.delete asset

    #-----------------------------
    # Step 1: Data consistency check
    #-----------------------------
    # TODO Not sure if this is needed, if we're moving it this will already have been done
    asset_data_consistency_check(asset, target_year, @start_year)

    add_to_project(asset, ali_code, target_year, current_project.capital_project_type)
  end



  #-----------------------------
  # Data consistency check
  #
  # Make sure that the asset has a in service date and a scheduled replacement year.
  # If the scheduled replacement year is not set, default it to the policy replacement year
  # or the first planning year if the asset is in backlog
  #
  #-----------------------------
  def asset_data_consistency_check(asset, target_year, start_year)
    changed = false
    if asset.in_service_date.nil?
      asset.in_service_date = asset.purchase_date
      changed = true
    end

    if target_year
      asset.scheduled_replacement_year = target_year
      changed = true
    elsif asset.scheduled_replacement_year.nil? || asset.scheduled_replacement_year < start_year
      if asset.policy_replacement_year < start_year
        # Take care of backlogged assets
        asset.scheduled_replacement_year = start_year
      else
        asset.scheduled_replacement_year = asset.policy_replacement_year
      end
      changed = true
    end

    # Default to replacing with new assets unless otherwise indicated
    if asset.scheduled_replace_with_new.blank?
      asset.scheduled_replace_with_new = true
      changed = true
    end

    # See if the asset has any scheduled replacement or rehabilitation costs, if not
    # use the estimated costs
    if asset.scheduled_replacement_cost.blank?
      Rails.logger.debug "asset scheduled_replacement_cost is blank, setting to est: #{asset.estimated_replacement_cost}"
      asset.scheduled_replacement_cost = asset.estimated_replacement_cost
      changed = true
    end

    if changed
      asset.save
    end
  end

  # Adds an asset to a SOGR project. If the project does not
  # exist it is created first,
  #
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
    project = CapitalProject.find_by('organization_id = ? AND team_ali_code_id = ? AND fy_year = ?', asset.organization.id, scope.id, year)
    if project.nil?
      # create this project
      project_title = "#{focus} #{request} project"
      project = create_capital_project(asset.organization, year, scope, project_title, project_type)
      project.save!
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

  # Returns the asset-specific ALI code for replacement
  def get_replace_ali_code(asset)
    ali_code = asset.policy_rule.replacement_ali_code
    scope = TeamAliCode.find_by_code(ali_code)
    scope
  end

  # Returns the asset-specific ALI code for rehabilitation
  def get_rehab_ali_code(asset)
    ali_code = asset.policy_rule.rehabilitation_ali_code
    scope = TeamAliCode.find_by_code(ali_code)
    scope
  end

  # Creates a new capital project
  def create_capital_project(org, fiscal_year, team_category, title, capital_project_type)

    project = CapitalProject.new
    project.organization = org
    project.active = true
    project.emergency = false
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

    @replacement_project_type = CapitalProjectType.find_by_code('R')
    @rehabilitation_project_type = CapitalProjectType.find_by_code('I')

    # These were in code but not used.
    # # Cache some commonly used objects
    # sys_user = User.find_by_first_name('system')
    # high_priority = PriorityType.find_by_name('High')

  end

end
