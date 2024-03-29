#-------------------------------------------------------------------------------
# CapitalProjectsController
#
# Basic Capital Project CRUD management
#
#-------------------------------------------------------------------------------
class CapitalProjectsController < AbstractCapitalProjectsController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Projects", :capital_projects_path

  before_action :get_project,       :except =>  [:index, :table, :create, :new, :runner, :builder, :get_dashboard_summary, :find_districts, :activity_line_items]

  INDEX_KEY_LIST_VAR    = "capital_project_key_list_cache_var"
  SESSION_VIEW_TYPE_VAR = 'capital_projects_subnav_view_type'

  def get_dashboard_summary
    respond_to do |format|
      format.js { render partial: 'dashboards/capital_projects_widget_table', locals: {fy_year: params[:fy_year] }  }
    end
  end

  #-----------------------------------------------------------------------------
  # Generic AJAX method for displaying a regular or modal view
  #-----------------------------------------------------------------------------
  def load_view

    @fiscal_years = (current_fiscal_year_year..current_fiscal_year_year + 49).map{ |y| [fiscal_year(y), y] }
    render params[:view]

  end
  #-----------------------------------------------------------------------------
  # Returns the ALIs for a project. Caller must pass in the view component to
  # be rendered
  #-----------------------------------------------------------------------------
  def alis

    @alis = @project.activity_line_items
    render params[:view]

  end

  #-----------------------------------------------------------------------------
  # Displays the SOGR analyzer form. When the form is commited the runner method
  # performs the analysis and generates the capital projects
  #-----------------------------------------------------------------------------
  def builder

    add_breadcrumb "SOGR Capital Project Analyzer"

    # Select the asset seed that they are allowed to build

    @asset_seed = []
    asset_class_name = Rails.application.config.asset_base_class_name == 'TransamAsset' ? 'TransitAsset' : Rails.application.config.asset_base_class_name

    asset_class_name.constantize.asset_seed_class_name.constantize.active.each do |seed|
      assets = asset_class_name.constantize.where(seed.class.to_s.underscore => seed)
      if assets.where(organization: @organization_list).count > 0
        @asset_seed << {id: seed.id, name: seed.to_s, orgs: @organization_list.select{|o| assets.where(organization_id: o).count > 0}}
      else
        @asset_seed << {id: seed.id, name: seed.to_s, orgs: []}
      end
    end

    @fiscal_years = get_fiscal_years(Date.today)
    @range_fiscal_years = ((1..14).to_a + (3..10).to_a.map{|x| x * 5}).map{|x| ["#{x} years", x-1]}
    @scenarios = Scenario.where(organization: current_user.viewable_organizations)
    @builder_proxy = BuilderProxy.new

    @has_locked_sogr_this_fiscal_year = CapitalPlanModule.joins(:capital_plan_module_type, :capital_plan).where(capital_plan_module_types: {name: ['Unconstrained Plan', 'Constrained Plan']}, capital_plans: {organization_id: @organization_list, fy_year: current_planning_year_year}).where('capital_plan_modules.completed_at IS NOT NULL').pluck('capital_plans.organization_id')

    if @organization_list.count == 1
      if @has_locked_sogr_this_fiscal_year && (@has_locked_sogr_this_fiscal_year.include? @organization_list.first)
        @fiscal_years = @fiscal_years[(@fiscal_years.index{|x| x[1]==current_planning_year_year}+1)..-1]
      end
      @builder_proxy.start_fy = current_planning_year_year
    else
      @has_sogr_project_org_list = CapitalProject.joins(:organization).where(organization_id: @organization_list).sogr.group(:organization_id).count
    end

    @message = "Creating SOGR capital projects. This process might take a while."

  end
  #-----------------------------------------------------------------------------
  # Processes the SOGR builder form and runs the SOGR builder service to generate
  # capital projects based on the user selections
  #-----------------------------------------------------------------------------
  def runner

    add_breadcrumb "SOGR Capital Project Analyzer", builder_capital_projects_path
    add_breadcrumb "Running..."

    @builder_proxy = BuilderProxy.new(params[:builder_proxy])
    if @builder_proxy.valid?

      if @builder_proxy.organization_id.blank?
        org_id = @organization_list.first
      else
        org_id = @builder_proxy.organization_id
      end
      org = Organization.get_typed_organization(Organization.find(org_id))

      # set class names whether primary or components are selected
      class_names = FtaAssetClass.where(id: @builder_proxy.fta_asset_classes).distinct.pluck(:class_name)




      ['Facility', 'Infrastructure'].each do |klass|
        if params["#{klass.downcase}_primary"].to_i == 1
          if params["#{klass.downcase}_component"].to_i == 1
            class_names << "#{klass}Component"
          else
            # do nothing Facility class already added from FTA asset class
          end
        else
          if params["#{klass.downcase}_component"].to_i == 1
            class_names << "#{klass}Component"
            class_names.delete(klass)
          else
            # this case can't happen but if it does
            class_names.delete(klass)
          end
        end
      end

      # save range of FYs for the org
      org.update(capital_projects_range_fys: @builder_proxy.range_fys.to_i)

      Delayed::Job.enqueue CapitalProjectBuilderJob.new(org, class_names, @builder_proxy.fta_asset_classes, @builder_proxy.start_fy, @builder_proxy.start_fy.to_i + @builder_proxy.range_fys.to_i, @builder_proxy.scenario_id, current_user), :priority => 0

      # Let the user know the results
      msg = "SOGR Capital Project Analyzer is running. You will be notified when the process is complete."
      notify_user(:notice, msg)

      if Rails.application.config.try(:use_new_scenarios_tool)
        redirect_to scenarios_url
      else
        redirect_to capital_projects_url
      end

      return
    else
      respond_to do |format|
        format.html { render :action => "builder" }
      end
    end

  end

  #-----------------------------------------------------------------------------
  # Search interface
  #-----------------------------------------------------------------------------
  def index
    @fiscal_years = get_fiscal_years

    # Filter by funding source and/or asset type. This takes more work and each uses a custom query to pre-select
    # capital projects that meet this partial match

    # Get the list of projects and set the view vars for filtering
    get_projects
    get_planning_years

    unless params[:format] == 'xls'
      # cache the set of object keys in case we need them later
      cache_list(@projects, INDEX_KEY_LIST_VAR)

      # generate the chart data
      if params[:format] != 'json'
        @report = Report.find_by_class_name('UnconstrainedCapitalNeedsForecast')
        report_instance = @report.class_name.constantize.new
        @data = report_instance.get_data_from_result_list(@projects)

        @alis = ActivityLineItem.where(capital_project_id: @projects.ids).distinct # override @alis to properly sum costs of capital projects
        @total_projects_cost_by_year =@alis.group("activity_line_items.fy_year").sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)
        @total_projects_cost = @total_projects_cost_by_year.map { |k,v| v}.sum
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json {
        projects_json = @projects.limit(params[:limit]).offset(params[:offset]).collect{ |p|
          p.as_json.merge!({
            popup_content: render_to_string(partial: 'capital_projects/activity_line_items_table', locals: {project: p, popup: '0'}, formats: 'html')
          })
        }
        render :json => {
          :total => @projects.count,
          :rows =>  projects_json
        }
      }
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=Capital Projects Table Export.xlsx"
      end
    end
  end

  #-----------------------------------------------------------------------------
  # TODO: MOST of this will be moved to a shareable module
  #-----------------------------------------------------------------------------
  def table
    projects = join_builder
    page = (table_params[:page] || 0).to_i
    page_size = (table_params[:page_size] || projects.count).to_i
    search = (table_params[:search])
    offset = page*page_size

    sort_column = table_params[:sort_column]
    sort_order = table_params[:sort_order]

    ### Update SORT Preferences ###
    if sort_column
      current_user.update_table_prefs(:projects, sort_column, sort_order)
    end

    query = nil 
    if search
      searchable_columns = [:project_number, :fy_year, :title]
      search_string = "%#{search}%"
      search_year = (is_number? search) ? search.to_i : nil  
      query = (query_builder(searchable_columns, search_string))
              .or(org_query search_string)
              .or(capital_project_type_query search_string)
      projects = projects.where(query)
    end

    projects = projects.order(current_user.table_sort_string :projects)
    
    project_table = projects.offset(offset).limit(page_size).map{ |p| p.rowify }
    render status: 200, json: {count: projects.count, rows: project_table} 

  end

  def join_builder 
    CapitalProject.joins(:organization)
                  .joins(:capital_project_type)
                  .joins('left join team_ali_codes on team_ali_code_id = team_ali_codes.id')
  end


  def is_number? string
    true if Float(string) rescue false
  end

  def org_query search_string
    Organization.arel_table[:name].matches(search_string).or(Organization.arel_table[:short_name].matches(search_string))
  end

  def capital_project_type_query search_string
    CapitalProjectType.arel_table[:name].matches(search_string)
  end

  def query_builder atts, search_string
    if atts.count <= 1
      return CapitalProject.joins(:organziation).arel_table[atts.pop].matches(search_string)
    else
      return CapitalProject.joins(:organization).arel_table[atts.pop].matches(search_string).or(query_builder(atts, search_string))
    end
  end

  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def show

    add_breadcrumb @project.project_number, capital_project_path(@project)

    # get the @prev_record_path and @next_record_path view vars
    get_next_and_prev_object_keys(@project, INDEX_KEY_LIST_VAR)
    @prev_record_path = @prev_record_key.nil? ? "#" : capital_project_path(@prev_record_key)
    @next_record_path = @next_record_key.nil? ? "#" : capital_project_path(@next_record_key)

    # get index of all projects and ALIS that respect the org and ALI filters
    get_projects

    respond_to do |format|
      format.html # show.html.erb
      format.js
      format.json { render :json => @project }
    end
  end

  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def new

    add_breadcrumb "New", new_capital_project_path

    @project = CapitalProject.new
    @fiscal_years = (current_fiscal_year_year..current_fiscal_year_year + 49).map{ |y| [fiscal_year(y), y] }

  end

  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def edit

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb "Modify", edit_capital_project_path(@project)

    @fiscal_years = (current_fiscal_year_year..current_fiscal_year_year + 49).map{ |y| [fiscal_year(y), y] }

  end

  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def copy

    new_project = @project.dup
    new_project.object_key = nil
    new_project.title = "Copy of #{@project.title}"
    new_project.save
    @project.activity_line_items.each do |ali|
      new_ali = ali.dup
      new_ali.object_key = nil
      new_project.activity_line_items << new_ali
    end

    notify_user(:notice, "Capital Project #{@project.project_number} was successfully copied to #{new_project.project_number}.")
    redirect_to edit_capital_project_url(new_project)

  end

  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def create

    add_breadcrumb "New", new_capital_project_path

    @project = CapitalProject.new(form_params)
    @project.organization_id = @organization_list.first if @organization_list.count == 1
    @fiscal_years = get_fiscal_years

    respond_to do |format|
      if @project.save
        notify_user(:notice, "Capital Project #{@project.project_number} was successfully created.")
        format.html { redirect_to capital_project_url(@project) }
        format.json { render :json => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        format.json { render :json => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def update

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb "Modify", edit_capital_project_path(@project)
    @fiscal_years = (current_fiscal_year_year..current_fiscal_year_year + 49).map{ |y| [fiscal_year(y), y] }

    respond_to do |format|
      if @project.update(form_params)
        @project.update_project_number
        @project.save
        notify_user(:notice, "Capital Project #{@project.name} was successfully updated.")
        format.html { redirect_back(fallback_location: root_path) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def destroy

    @project.destroy
    notify_user(:notice, "Capital Project was successfully removed.")
    respond_to do |format|
      format.html {
        # See if we got a view to render
        if params[:view] == "back"
          redirect_back(fallback_location: root_path)
        elsif params[:view] == "planning"
          redirect_to planning_index_url
        else
          redirect_to capital_projects_url
        end
      }
      format.json { head :no_content }
    end
  end

  #-----------------------------------------------------------------------------
  # ajax called method used to find the distrcits for an organization to auto-populate on capital project loading
  #-----------------------------------------------------------------------------
  def find_districts
    organization_id = params[:district_desired_org_id]
    districts = FtaAgency.find_by(id: organization_id).districts

    result = []
    districts.each { |d|
      entry = []
      entry << d.id
      entry << d.to_s
      result << entry
      }

    @organization_distrcits = result
    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

  #-----------------------------------------------------------------------------
  # Get all ALIs for selected projects.
  #-----------------------------------------------------------------------------
  def activity_line_items

    get_projects

    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=Activity Line Items Table Export.xlsx"
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Protected Methods
  #-----------------------------------------------------------------------------
  protected


  #-----------------------------------------------------------------------------
  # Private methods
  #-----------------------------------------------------------------------------
  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:capital_project).permit(CapitalProject.allowable_params)
  end

  def table_params
    params.permit(:page, :page_size, :search, :sort_column, :sort_order)
  end

end
