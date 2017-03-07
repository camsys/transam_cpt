#-------------------------------------------------------------------------------
# AbstractCapitalProjectsController
#
# Base class for controllers that need to search or view capital projects
#
#-------------------------------------------------------------------------------
class AbstractCapitalProjectsController < OrganizationAwareController

  # Include the fiscal year mixin
  include FiscalYear

  EMERGENCY_FLAG = '1'
  SOGR_FLAG = '2'
  SHADOW_FLAG = '3'
  MULTI_YEAR_FLAG = '4'

  CAPITAL_PROJECT_FLAGS = [
    ["Emergency", EMERGENCY_FLAG],
    ["SOGR", SOGR_FLAG],
    ["Shadow", SHADOW_FLAG],
    ["Multi-year", MULTI_YEAR_FLAG]
  ]

  #-----------------------------------------------------------------------------
  # Fires a workflow event for a capital project
  #-----------------------------------------------------------------------------
  def fire_workflow_event

    # Check that this is a valid event name for the state machines
    if @project.class.event_names.include? params[:event]
      event_name = params[:event]
      if @project.fire_state_event(event_name)
        event = WorkflowEvent.new
        event.creator = current_user
        event.accountable = @project
        event.event_type = event_name
        event.save
        notify_user(:notice, "Capital Project #{@project.project_number} is now #{@project.state.humanize}.")
      else
        notify_user(:alert, "Could not #{event_name.humanize} capital project #{@project.project_number}")
      end
    else
      notify_user(:alert, "#{params[:event_name]} is not a valid event for a #{@project.class.name}")
    end

    redirect_to :back

  end

  #-----------------------------------------------------------------------------
  # Protected Methods
  #-----------------------------------------------------------------------------
  protected

  #-----------------------------------------------------------------------------
  # Return a possibly filtered set of capital projects. Sets the following
  # view variables
  #   @projects                     -- list of matching capital projects
  #   @org_filter                   -- list of selected organization ids
  #   @fiscal_year_filter           -- list of selected fiscal years
  #   @capital_project_type_filter  -- list of selected capital project types
  #   @capital_project_flag_filter  -- list of selected capital project flags
  #   @asset_subtype_filter         -- list of selected asset subtype ids
  #   @funding_source_filter        -- list of selected funding source ids
  #-----------------------------------------------------------------------------
  def get_projects

    @user_activity_line_item_filter = current_user.user_activity_line_item_filter

    # Start to set up the query
    conditions  = []
    values      = []

    #-----------------------------------------------------------------------------
    #
    # Steps
    #
    #
    # 1. parameters on assets within ALIs
    # 2. parameters on ALIs within projects
    # 3. parameters on projects
    #
    # 1. Search for assets that meet given parameters (type, subtype, etc.) Returns all ALIs with those assets.
    # 2. Given ALIs from above, return subset that meet ALI parameters. Get projects from that subset.
    # 3. Given projects from above return all projects that meet project parameters.
    #
    #-----------------------------------------------------------------------------

    # Use ALI as the base relation to deal with asset & ALI filters
    @alis = ActivityLineItem.distinct

    #-----------------------------------------------------------------------------
    # Asset parameters
    #-----------------------------------------------------------------------------

    # Filter by asset type and subtype. Requires joining across CP <- ALI <- ALI-Assets <- Assets
    asset_conditions  = []
    asset_values      = []
    if @user_activity_line_item_filter.try(:asset_subtype_id).present?
      @asset_subtype_filter = [@user_activity_line_item_filter.asset_subtype_id]
      asset_conditions << 'assets.asset_subtype_id IN (?)'
      asset_values << @asset_subtype_filter
    elsif @user_activity_line_item_filter.try(:asset_type_id).present?
      @asset_subtype_filter = AssetSubtype.where(asset_type_id: @user_activity_line_item_filter.asset_type_id).pluck(:id)
      asset_conditions << 'assets.asset_subtype_id IN (?)'
      asset_values << @asset_subtype_filter
    end

    # filter by backlog
    if @user_activity_line_item_filter.try(:in_backlog)
      asset_conditions << 'assets.in_backlog = ?'
      asset_values << true
    end

    unless asset_conditions.empty?
      # always filter assets by org params
      asset_conditions << 'assets.organization_id IN (?)'
      asset_values << @organization_list

      @alis = @alis.joins(:assets).where(asset_conditions.join(' AND '), *asset_values)
    end
    #-----------------------------------------------------------------------------


    #-----------------------------------------------------------------------------
    # CapitalProject specific
    #-----------------------------------------------------------------------------
    # get the projects based on filtered ALIs

    # dont impose ALI/asset conditions unless they were in the params
    no_ali_or_asset_params_exist = (@user_activity_line_item_filter.attributes.slice('asset_subtype_id', 'asset_type_id', 'in_backlog', 'funding_bucket_id', 'not_fully_funded').values.uniq == [nil])
    if no_ali_or_asset_params_exist
      @projects = CapitalProject.order(:fy_year, :capital_project_type_id, :created_at)
    else
      @projects = CapitalProject.where(id: @alis.uniq(:capital_project_id).pluck(:capital_project_id)).order(:fy_year, :capital_project_type_id, :created_at)
    end

    # org id is not tied to ALI filter
    # org id is used in scheduler though not necessary but all links specify looking at a single org at a time
    # other functionality like planning does not require
    if params[:org_id].blank?
      conditions << 'capital_projects.organization_id IN (?)'
      values << @organization_list
    else
      @org_id = params[:org_id].to_i
      conditions << 'capital_projects.organization_id = ?'
      values << @org_id
    end

    @capital_project_flag_filter = []

    capital_project_types = (@user_activity_line_item_filter.try(:capital_project_type_id).blank? ? [] : [@user_activity_line_item_filter.capital_project_type_id] )
    sogr_types = []
    if @user_activity_line_item_filter.try(:sogr_type) == 'SOGR'
      sogr_types = [CapitalProjectType.find_by(name: 'Replacement').id]
      conditions << 'capital_projects.sogr = ?'
      values << true
    elsif @user_activity_line_item_filter.try(:sogr_type) == 'Non-SOGR'
      conditions << 'capital_projects.sogr = ?'
      values << false
    end

    @capital_project_type_filter = (capital_project_types & sogr_types)
    unless @capital_project_type_filter.empty?
      conditions << 'capital_projects.capital_project_type_id IN (?)'
      values << @capital_project_type_filter
    end

    # TEAM ALI code
    if @user_activity_line_item_filter.try(:team_ali_code_id).blank?
      @team_ali_code_filter = []
    else
      @team_ali_code_filter = [@user_activity_line_item_filter.team_ali_code_id]

      conditions << 'capital_projects.team_ali_code_id IN (?)'
      values << @team_ali_code_filter
    end

    #-----------------------------------------------------------------------------


    #-----------------------------------------------------------------------------
    # Parse non-common filters
    # filter values come from request params

    @fiscal_year_filter = params[:fiscal_year_filter]

    if @fiscal_year_filter.blank?
      @fiscal_year_filter = []
    else
      conditions << 'capital_projects.fy_year IN (?)'
      values << @fiscal_year_filter
    end
    #-----------------------------------------------------------------------------

    # final results
    @projects = @projects.where(conditions.join(' AND '), *values)

    @alis = ActivityLineItem.where(capital_project_id: @projects.ids) if no_ali_or_asset_params_exist
  end

  def get_planning_years
    # This is the first year that the user can plan for
    @first_year = current_planning_year_year
    # This is the last year  the user can plan for
    @last_year = last_fiscal_year_year
    # This is an array of years that the user can plan for
    @years = (@first_year..@last_year).to_a
  end

  #-----------------------------------------------------------------------------
  # Sets the @project view var
  #-----------------------------------------------------------------------------
  def get_project
    @project = CapitalProject.find_by(object_key: params[:id], organization_id: @organization_list) unless params[:id].nil?
    # if not found or the object does not belong to the users
    if @project.nil?
      if CapitalProject.find_by(object_key: params[:id], :organization_id => current_user.user_organization_filters.system_filters.first.get_organizations.map{|x| x.id}).nil?
        redirect_to '/404'
      else
        notify_user(:warning, 'This record is outside your filter. Change your filter if you want to access it.')
        redirect_to capital_projects_path
      end
      return
    end

  end

  #-----------------------------------------------------------------------------
  # Private Methods
  #-----------------------------------------------------------------------------
  private

end
