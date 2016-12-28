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

  # Start to set up the query
  conditions  = []
  values      = []

  #-----------------------------------------------------------------------------

   # Check to see if we got an organization to sub select on.
   conditions << 'organization_id IN (?)'
   if @org_filter.blank?
     values << @organization_list
     @org_filter = []
   else
     values << @org_filter
   end

   if @capital_project_type_filter.blank?
     @capital_project_type_filter = []
   else
     conditions << 'capital_project_type_id IN (?)'
     values << @capital_project_type_filter
   end

   if @capital_project_flag_filter.blank?
     @capital_project_flag_filter = []
   else
     if @capital_project_flag_filter.include? EMERGENCY_FLAG
       conditions << 'emergency = ?'
       values << true
     end
     if @capital_project_flag_filter.include? SOGR_FLAG
       conditions << 'sogr = ?'
       values << true
     end
     if @capital_project_flag_filter.include? SHADOW_FLAG
       conditions << 'notional = ?'
       values << true
     end
     if @capital_project_flag_filter.include? MULTI_YEAR_FLAG
       conditions << 'multi_year = ?'
       values << true
     end
   end

   # Filter by asset type. Requires joining across CP <- ALI <- ALI-Assets <- Assets
   if @asset_subtype_filter.blank?
     @asset_subtype_filter = []
   else
     capital_project_ids = []
     # first get a list of matching asset ids for the selected organizations. This is better as a ruby query
     asset_ids = Asset.where('asset_subtype_id IN (?) AND organization_id IN (?)', @asset_subtype_filter, values[0]).pluck(:id)
     unless asset_ids.empty?
       # now get CPs by subselecting on CP <- ALI <- ALI-Assets
       query = "SELECT DISTINCT(id) FROM capital_projects WHERE capital_projects.id IN (SELECT DISTINCT(capital_project_id) FROM activity_line_items WHERE activity_line_items.id IN (SELECT DISTINCT(activity_line_item_id) FROM activity_line_items_assets WHERE asset_id IN (#{asset_ids.join(',')})))"
       cps = CapitalProject.connection.execute(query, :skip_logging)
       cps.each do |cp|
         capital_project_ids << cp[0]
       end
     end
     conditions << 'capital_projects.id IN (?)'
     values << capital_project_ids.uniq  # make sure there are no duplicates
   end

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

   # Filter by Funding Source. Requires joining across CP <- ALI <- FR <- FA <- FS
   @funding_source_filter = params[:funding_source_filter]
   if @funding_source_filter.blank?
     @funding_source_filter = []
   else
     capital_project_ids = []
     funding_source_ids = FundingSource.where(:funding_source_id => @funding_source_filter).pluck(:id)
     unless funding_source_ids.empty?
       # Use a custom query to join across the five tables
       query = "SELECT DISTINCT(id) FROM capital_projects WHERE id IN (SELECT DISTINCT(capital_project_id) FROM activity_line_items WHERE id IN (SELECT activity_line_item_id FROM funding_requests WHERE #{column_name} IN (SELECT id FROM funding_line_items WHERE funding_source_id IN (#{funding_source_ids.join(',')})))"
       cps = CapitalProject.connection.execute(query, :skip_logging)
       cps.each do |cp|
         capital_project_ids << cp[0]
       end
       conditions << 'id IN (?)'
       values << capital_project_ids.uniq  # make sure there are no duplicates
     end
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
