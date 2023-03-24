#-------------------------------------------------------------------------------
# Draft Projects Controller
#
# Basic Draft ProjectCRUD management
#
#-------------------------------------------------------------------------------
class DraftProjectsController < OrganizationAwareController
  include FiscalYear

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Scenarios", :scenarios_path

  INDEX_KEY_LIST_VAR    = "capital_project_key_list_cache_var"

  def index
    add_breadcrumb "Projects"
    
    # Get the list of projects 
    get_projects

    unless params[:format] == 'xls'
      # cache the set of object keys in case we need them later
      cache_list(@projects, INDEX_KEY_LIST_VAR)

      if params[:format] != 'json'
        @phases = DraftProjectPhase.where(draft_project_id: @projects.ids).distinct # override to properly sum costs of projects
        @total_projects_cost_by_year = @phases.group("draft_project_phases.fy_year").sum(:cost)
        @total_projects_cost = @total_projects_cost_by_year.map { |k,v| v}.sum
      end
    end

    respond_to do |format|
      format.html
      format.json {
        projects_json = @projects.limit(params[:limit]).offset(params[:offset]).collect{ |p| p.as_json }
        render :json => {
                 :total => @projects.count,
                 :rows =>  projects_json
               }
      }
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=Draft Projects Table Export.xlsx"
      end
    end
  end

  def show
    set_draft_project
    add_breadcrumb @draft_project.scenario.name, scenario_path(@draft_project.scenario)
    add_breadcrumb "#{@draft_project.title}"

    respond_to do |format|
      format.html
    end
    
  end

  def edit
    set_draft_project
    @districts = Organization.get_typed_organization(@draft_project.scenario.organization).districts
    add_breadcrumb @draft_project.scenario.name, scenario_path(@draft_project.scenario)
    add_breadcrumb "#{@draft_project.title}"
    
    respond_to do |format|
      format.html
    end
  end

  def new 
    @draft_project = DraftProject.new 
    @scenario = Scenario.find_by(object_key: scenario_params[:scenario_id])
    @districts = Organization.get_typed_organization(@scenario.organization).districts
    @draft_project.scenario = @scenario 
    add_breadcrumb @draft_project.scenario.name, scenario_path(@draft_project.scenario)
    add_breadcrumb "New Project"

    respond_to do |format|
      format.html
    end
  end

  def create 
    @draft_project = DraftProject.new

    respond_to do |format|
      if @draft_project.update(form_params)
        add_districts
        format.html { redirect_to draft_project_path(@draft_project) }
      else
        notify_user(:alert, @draft_project.errors.full_messages.join("; "))
        format.html {redirect_back(fallback_location: root_path)}
      end
    end
  end

  def update
    set_draft_project

    respond_to do |format|
      if @draft_project.update(form_params)
        add_districts
        format.html { redirect_to draft_project_path(@draft_project) }
      else
        notify_user(:alert, @draft_project.errors.full_messages.join("; "))
        format.html {redirect_back(fallback_location: root_path)}
      end
    end
  end

  def destroy
    set_draft_project
    scenario = @draft_project.scenario
    @draft_project.destroy

    redirect_to scenario_path(scenario)
  end

  def export_to_csv 
    fy_year = params[:fy_year].to_i
    @scenarios = Scenario.in_submitted_state.where(fy_year: fy_year)

    respond_to do |format|
      format.html { send_data DraftProject.to_csv(@scenarios), filename: "unconstrained_capital_projects_report.csv", type: :csv, disposition: "attachment" }
    end
  end

  #-----------------------------------------------------------------------------
  # Get all phases for selected projects.
  #-----------------------------------------------------------------------------
  def phases
    get_projects

    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=Phases Table Export.xlsx"
      end
    end
  end

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
    @phases = DraftProjectPhase
    no_ali_or_asset_params_exist = true

    #-----------------------------------------------------------------------------
    # Asset parameters
    #-----------------------------------------------------------------------------

    # Filter by asset type and subtype. Requires joining across CP <- ALI <- ALI-Assets <- Assets
    asset_search = Hash.new
    asset_table = Rails.application.config.asset_base_class_name.constantize.table_name
    asset_search[asset_table.to_sym] = Hash.new

    if @user_activity_line_item_filter.try(:asset_subtypes).present?
      @asset_subtype_filter = @user_activity_line_item_filter.asset_subtypes.split(',')

      asset_search[asset_table.to_sym][:asset_subtype_id] = @asset_subtype_filter
      no_ali_or_asset_params_exist = false
    elsif @user_activity_line_item_filter.try(:asset_types).present? && (Rails.application.config.asset_base_class_name.constantize.column_names.include? :asset_type_id)
      @asset_subtype_filter = AssetSubtype.where(asset_type_id: @user_activity_line_item_filter.asset_types.split(',')).pluck(:id)
      asset_search[asset_table.to_sym][:asset_subtype_id] = @asset_subtype_filter
      no_ali_or_asset_params_exist = false
    end

    if @user_activity_line_item_filter.try(:fta_asset_classes).present?
      asset_search[:transit_assets] = {fta_asset_class_id: @user_activity_line_item_filter.fta_asset_classes.split(',')}
      no_ali_or_asset_params_exist = false
    end

    # filter by backlog
    if @user_activity_line_item_filter.try(:in_backlog)
      asset_search[asset_table.to_sym][:in_backlog] = true
      no_ali_or_asset_params_exist = false
    end

    if @user_activity_line_item_filter.try(:asset_query_string)
      asset_search[asset_table.to_sym][:object_key] = Rails.application.config.asset_base_class_name.constantize.find_by_sql(@user_activity_line_item_filter.asset_query_string).map{|x| x.object_key}
      no_ali_or_asset_params_exist = false
    end

    unless asset_search[asset_table.to_sym].empty? && asset_search.keys.count == 1

      asset_search[asset_table.to_sym][:organization_id] = @organization_list

      @phases = @phases.where(asset_search)

      if Rails.application.config.asset_base_class_name == 'TransamAsset'
        @phases = @phases.joins(transit_assets: :transam_asset)
      end
    end
    #-----------------------------------------------------------------------------


    #-----------------------------------------------------------------------------
    # DraftProject specific
    #-----------------------------------------------------------------------------
    # get the projects based on filtered ALIs

    # dont impose ALI/asset conditions unless they were in the params
    @projects = DraftProject.includes(:capital_project_type,:team_ali_code)
    unless no_ali_or_asset_params_exist
      @projects = DraftProject.includes(:capital_project_type,:team_ali_code).where(id: @phases.distinct(:draft_project_id).pluck(:draft_project_id))
    end

    # org id is not tied to ALI filter
    # org id is used in scheduler though not necessary but all links specify looking at a single org at a time
    # other functionality like planning does not require
    if params[:org_id].blank?
      conditions << 'scenarios.organization_id IN (?)'
      values << @organization_list
    else
      @org_id = params[:org_id].to_i
      conditions << 'scenarios.organization_id = ?'
      values << @org_id
    end

    @capital_project_flag_filter = []

    capital_project_types = (@user_activity_line_item_filter.try(:capital_project_type_id).blank? ? [] : [@user_activity_line_item_filter.capital_project_type_id] )
    sogr_types = []
    if @user_activity_line_item_filter.try(:sogr_type) == 'SOGR'
      sogr_types = [CapitalProjectType.find_by(name: 'Replacement').id]
      conditions << 'draft_projects.sogr = ?'
      values << true
    elsif @user_activity_line_item_filter.try(:sogr_type) == 'Non-SOGR'
      conditions << 'draft_projects.sogr = ?'
      values << false
    end

    @capital_project_type_filter = (capital_project_types & sogr_types)
    unless @capital_project_type_filter.empty?
      conditions << 'draft_projects.capital_project_type_id IN (?)'
      values << @capital_project_type_filter
    end

    # TEAM ALI code
    if @user_activity_line_item_filter.try(:team_ali_codes).blank?
      @team_ali_code_filter = []
      else
      @team_ali_code_filter = @user_activity_line_item_filter.team_ali_codes.split(',')

      conditions << 'draft_projects.team_ali_code_id IN (?)'
      values << @team_ali_code_filter
    end

    if @user_activity_line_item_filter.try(:planning_year)
      @fy_year_filter = [current_planning_year_year]

      conditions << 'scenarios.fy_year IN (?)'
      values << @fy_year_filter
    else
      @fy_year_filter = []
    end

    # District
    if @user_activity_line_item_filter.try(:districts).blank?
      @district_filter = []
    else
      @district_filter = @user_activity_line_item_filter.districts.split(',')
      conditions << 'draft_projects.id IN (SELECT DISTINCT draft_projects_districts.draft_project_id FROM draft_projects_districts WHERE draft_projects_districts.district_id IN (?))'
      values << @district_filter
    end

    #-----------------------------------------------------------------------------


    #-----------------------------------------------------------------------------
    # Parse non-common filters
    # filter values come from request params

    @fiscal_year_filter = params[:fiscal_year_filter]

    if @fiscal_year_filter.blank?
      @fiscal_year_filter = []
    else
      conditions << 'scenarios.fy_year IN (?)'
      values << @fiscal_year_filter
    end
    #-----------------------------------------------------------------------------

    # final results
    @projects = @projects.joins(:organization).where(conditions.join(' AND '), *values).order('organizations.short_name', :fy_year, :project_number)

    @phases = DraftProjectPhase.where(draft_project_id: @projects.ids)
  end
  
  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:draft_project).permit(DraftProject.allowable_params)
  end

  def add_districts
    districts = District.where(id: district_ids)
    @draft_project.districts = districts 
  end 

  def district_ids
    params["draft_project"].try(:[], "district_ids")
  end

  def table_params
    params.permit(:page, :page_size, :search, :sort_column, :sort_order)
  end

  def scenario_params
    params.permit(:scenario_id)
  end

  def set_draft_project
    @draft_project = DraftProject.find_by(object_key: params[:id]) 
  end

end
