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

    #TODO redo this whole section

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


    #-----------------------------------------------------------------------------
    # Project parameters
    #-----------------------------------------------------------------------------
    conditions << 'organization_id IN (?)'
    values << @organization_list

    @capital_project_flag_filter = []

    capital_project_types = (@user_activity_line_item_filter.try(:capital_project_type_id).blank? ? [] : [@user_activity_line_item_filter.capital_project_type_id] )
    sogr_types = []
    if @user_activity_line_item_filter.try(:sogr_type) == 'SOGR'
      sogr_types = [CapitalProjectType.find_by(name: 'Replacement').id]
      conditions << 'sogr = ?'
      values << true
    elsif @user_activity_line_item_filter.try(:sogr_type) == 'Non-SOGR'
      conditions << 'sogr = ?'
      values << false
    end

    @capital_project_type_filter = (capital_project_types & sogr_types)
    unless @capital_project_type_filter.empty?
      conditions << 'capital_project_type_id IN (?)'
      values << @capital_project_type_filter
    end

    #-----------------------------------------------------------------------------


    #-----------------------------------------------------------------------------
    # Asset parameters
    #-----------------------------------------------------------------------------

    # Filter by asset type and subtype. Requires joining across CP <- ALI <- ALI-Assets <- Assets
    asset_conditions  = []
    asset_values      = []
    if @user_activity_line_item_filter.try(:asset_subtype_id).present?
      @asset_subtype_filter = [@user_activity_line_item_filter.asset_subtype_id]
      asset_conditions << 'asset_subtype_id IN (?)'
      asset_values << @asset_subtype_filter
    elsif @user_activity_line_item_filter.try(:asset_type_id).present?
      @asset_subtype_filter = AssetType.find_by(id: @user_activity_line_item_filter.asset_type_id).asset_subtypes.ids
      asset_conditions << 'asset_subtype_id IN (?)'
      asset_values << @asset_subtype_filter
    end

    # filter by backlog
    if @user_activity_line_item_filter.try(:in_backlog)
      asset_conditions << 'in_backlog = ?'
      asset_values << true
    end

    # always filter assets by org params
    asset_conditions << 'organization_id IN (?)'
    asset_values << values[0]

    ali_asset_conditions = []
    ali_asset_values = []
    unless asset_conditions.empty?
      ali_asset_conditions << 'activity_line_items_assets.asset_id IN (?)'
      ali_asset_values << Asset.where(asset_conditions.join(' AND '), *asset_values).pluck(:id)
    end

    #-----------------------------------------------------------------------------


    #-----------------------------------------------------------------------------
    # ALI parameters
    #-----------------------------------------------------------------------------

    # TEAM ALI code
    if @user_activity_line_item_filter.try(:team_ali_code_id).blank?
      @team_ali_code_filter = []
    else
      @team_ali_code_filter = [@user_activity_line_item_filter.team_ali_code_id]

      ali_asset_conditions << 'activity_line_items_assets.activity_line_item_id IN (?)'
      ali_asset_values << ActivityLineItem.where(team_ali_code_id: @team_ali_code_filter).ids
    end

    unless ali_asset_conditions.empty?
      conditions << 'capital_projects.id IN (?)'
      values << ActivityLineItem.joins('INNER JOIN activity_line_items_assets ON activity_line_items_assets.activity_line_item_id = activity_line_items.id').where(ali_asset_conditions.join(' AND '), *ali_asset_values).pluck(:capital_project_id).uniq
    end

    # TODO: add params for below when we do tagging
    # funding bucket

    # Filter by Funding Source. Requires joining across CP <- ALI <- FR <- FA <- FS
    # @funding_source_filter = params[:funding_source_filter]
    # if @funding_source_filter.blank?
    #   @funding_source_filter = []
    # else
    #   capital_project_ids = []
    #   funding_source_ids = FundingSource.where(:funding_source_id => @funding_source_filter).pluck(:id)
    #   unless funding_source_ids.empty?
    #     # Use a custom query to join across the five tables
    #     query = "SELECT DISTINCT(id) FROM capital_projects WHERE id IN (SELECT DISTINCT(capital_project_id) FROM activity_line_items WHERE id IN (SELECT activity_line_item_id FROM funding_requests WHERE #{column_name} IN (SELECT id FROM funding_line_items WHERE funding_source_id IN (#{funding_source_ids.join(',')})))"
    #     cps = CapitalProject.connection.execute(query, :skip_logging)
    #     cps.each do |cp|
    #       capital_project_ids << cp[0]
    #     end
    #     conditions << 'id IN (?)'
    #     values << capital_project_ids.uniq  # make sure there are no duplicates
    #   end
    # end


    # not fully funded

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

   # Get the initial list of capital projects. These might need to be filtered further if the user specified a funding source filter
   @projects = CapitalProject.where(conditions.join(' AND '), *values).order(:fy_year, :capital_project_type_id, :created_at)

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
