#-------------------------------------------------------------------------------
# CapitalProjectsController
#
# Basic Capital Project CRUD management
#
#-------------------------------------------------------------------------------
class CapitalProjectsController < AbstractCapitalProjectsController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path

  before_filter :get_project,       :except =>  [:index, :create, :new, :runner, :builder]

  INDEX_KEY_LIST_VAR    = "capital_project_key_list_cache_var"
  SESSION_VIEW_TYPE_VAR = 'capital_projects_subnav_view_type'

  #-----------------------------------------------------------------------------
  # Generic AJAX method for displaying a regular or modal view
  #-----------------------------------------------------------------------------
  def load_view

    @fiscal_years = get_fiscal_years
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

    # Select the asset types that they are allowed to build. This is narrowed down to only
    # asset types they own and those which are fta vehicles
    builder = CapitalProjectBuilder.new
    #@asset_types = builder.eligible_asset_types(@organization)
    @asset_types = []
    AssetType.all.each do |type|
      assets = Asset.where(asset_type: type)
      if assets.where(organization: @organization_list).count > 0
        @asset_types << {id: type.id, name: type.to_s, orgs: @organization_list.select{|o| assets.where(organization_id: o).count > 0}}
      end
    end

    @fiscal_years = get_fiscal_years
    @builder_proxy = BuilderProxy.new

    if @organization_list.count == 1
      if @organization.has_sogr_projects?
        @builder_proxy.start_fy = current_planning_year_year + 3
      else
        @builder_proxy.start_fy = current_planning_year_year
      end
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
        org = @organization
      else
        org = Organization.get_typed_organization(Organization.find(@builder_proxy.organization_id))
      end

      Delayed::Job.enqueue CapitalProjectBuilderJob.new(org, @builder_proxy.asset_types, @builder_proxy.start_fy, current_user), :priority => 0

      # Let the user know the results
      msg = "SOGR Capital Project Analyzer is running. You will be notified when the process is complete."
      notify_user(:notice, msg)

      redirect_to capital_projects_url
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

    unless params[:format] == 'xls'
      # cache the set of object keys in case we need them later
      cache_list(@projects, INDEX_KEY_LIST_VAR)

      # generate the chart data
      if params[:format] != 'json'
        @report = Report.find_by_class_name('UnconstrainedCapitalNeedsForecast')
        report_instance = @report.class_name.constantize.new
        @data = report_instance.get_data_from_result_list(@projects)

        @total_projects_cost_by_year = @projects.joins(:activity_line_items).group("activity_line_items.fy_year").sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)
        @total_projects_cost = @total_projects_cost_by_year.map { |k,v| v}.sum
        @total_projects_state_funds = @projects.total_state_funds
        @total_projects_federal_funds = @projects.total_federal_funds
        @total_projects_local_funds = @projects.total_local_funds
        @total_projects__funds = @projects.total_funds
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
      format.xls
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

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @project }
    end
  end

  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def new

    add_breadcrumb "New", new_capital_project_path

    @project = CapitalProject.new
    @fiscal_years = get_fiscal_years

  end

  #-----------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------
  def edit

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb "Modify", edit_capital_project_path(@project)

    @fiscal_years = get_fiscal_years

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
    @project.organization = @organization if @project.organization_id.nil?
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
    @fiscal_years = get_fiscal_years

    respond_to do |format|
      if @project.update_attributes(form_params)
        @project.update_project_number
        @project.save
        notify_user(:notice, "Capital Project #{@project.name} was successfully updated.")
        format.html { redirect_to :back }
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
          redirect_to :back
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

end
