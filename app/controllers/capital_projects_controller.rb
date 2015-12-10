class CapitalProjectsController < OrganizationAwareController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path

  # Include the fiscal year mixin
  include FiscalYear

  #before_filter :authorize_admin
  before_filter :check_for_cancel,  :only =>    [:create, :update, :runner]
  before_filter :get_project,       :except =>  [:index, :create, :new, :runner, :builder]

  INDEX_KEY_LIST_VAR    = "capital_project_key_list_cache_var"
  SESSION_VIEW_TYPE_VAR = 'capital_projects_subnav_view_type'

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
    @asset_types = builder.eligible_asset_types(@organization)
    @fiscal_years = get_fiscal_years
    @builder_proxy = BuilderProxy.new

    if @organization.has_sogr_projects?
      @builder_proxy.start_fy = current_planning_year_year + 3
    else
      @builder_proxy.start_fy = current_planning_year_year
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
      # Sleep for a couple of seconds so that the screen can display the waiting
      # message and the user can read it.
      sleep 2

      # Run the builder
      options = {}
      options[:asset_type_ids] = @builder_proxy.asset_types
      options[:start_fy] = @builder_proxy.start_fy

      #puts options.inspect
      builder = CapitalProjectBuilder.new
      num_created = builder.build(@organization, options)

      # Let the user know the results
      if num_created > 0
        msg = "SOGR Capital Project Analyzer completed. #{num_created} SOGR capital projects were added to your capital needs list."
        notify_user(:notice, msg)
        # Add a row into the activity table
        ActivityLog.create({:organization_id => @organization.id, :user_id => current_user.id, :item_type => "CapitalProjectBuilder", :activity => msg, :activity_time => Time.now})
      else
        notify_user(:notice, "No capital projects were created.")
      end
      redirect_to capital_projects_url
      return
    else
      respond_to do |format|
        format.html { render :action => "builder" }
      end
    end

  end

  def index

    @fiscal_years = get_fiscal_years

     # Start to set up the query
    conditions  = []
    values      = []

    # Check to see if we got an organization to sub select on.
    @org_filter = params[:org_filter]
    conditions << 'organization_id IN (?)'
    if @org_filter.blank?
      values << @organization_list
    else
      values << @org_filter
    end

    @capital_project_filter = params[:capital_project_filter]
    unless @capital_project_filter.blank?
      conditions << 'capital_project_type_id IN (?)'
      values << @capital_project_filter
    end

    # See if we got search
    @fiscal_year_filter = params[:fiscal_year_filter]
    unless @fiscal_year_filter.blank?
      conditions << 'fy_year IN (?)'
      values << @fiscal_year_filter
    end


    # Filter by asset type. Requires jopining across CP <- ALI <- ALI-Assets <- Assets
    @asset_subtype_filter = params[:asset_subtype_filter]
    unless @asset_subtype_filter.blank?
      capital_project_ids = []
      # first get a list of matching asset ids for the selected organizations. This is better as a ruby query
      asset_ids = Asset.where('asset_subtype_id IN (?) AND organization_id IN (?)', @asset_subtype_filter, values[0]).pluck(:id)
      unless asset_ids.empty?
        # now get CPs by subselecting on CP <- ALI <- ALI-Assets
        query = "SELECT DISTINCT(id) FROM capital_projects WHERE id IN (SELECT DISTINCT(capital_project_id) FROM activity_line_items WHERE id IN (SELECT DISTINCT(activity_line_item_id) FROM activity_line_items_assets WHERE asset_id IN (#{asset_ids.join(',')})))"
        cps = CapitalProject.connection.execute(query, :skip_logging)
        cps.each do |cp|
          capital_project_ids << cp[0]
        end
      end
      conditions << 'id IN (?)'
      values << capital_project_ids.uniq  # make sure there are no duplicates
    end

    # Filter by funding source and/or asset type. This takes more work and each uses a custom query to pre-select
    # capital projects that meet this partial match

    # Funding Source. Requires joining across CP <- ALI <- FR <- FA <- FS
    @funding_source_id = params[:funding_source_id]
    unless @funding_source_id.blank?
      funding_source = FundingSource.find(@funding_source_id)
      @funding_source_id = funding_source.id
      column_name = funding_source.federal? ? 'federal_funding_line_item_id' : 'state_funding_line_item_id'
      if @funding_source_id > 0
        capital_project_ids = []
        # Use a custom query to join across the five tables
        query = "SELECT DISTINCT(id) FROM capital_projects WHERE id IN (SELECT DISTINCT(capital_project_id) FROM activity_line_items WHERE id IN (SELECT activity_line_item_id FROM funding_requests WHERE #{column_name} IN (SELECT id FROM funding_line_items WHERE funding_source_id = #{@funding_source_id})))"
        cps = CapitalProject.connection.execute(query, :skip_logging)
        cps.each do |cp|
          capital_project_ids << cp[0]
        end
        conditions << 'id IN (?)'
        values << capital_project_ids.uniq  # make sure there are no duplicates
      end
    end

    #puts conditions.inspect
    #puts values.inspect

    # Get the initial list of capital projects. These might need to be filtered further if the user specified a funding source filter
    @projects = CapitalProject.where(conditions.join(' AND '), *values).order(:fy_year, :capital_project_type_id, :created_at)

    unless params[:format] == 'xls'
      # cache the set of object keys in case we need them later
      cache_list(@projects, INDEX_KEY_LIST_VAR)

      # generate the chart data
      @report = Report.find_by_class_name('UnconstrainedCapitalNeedsForecast')
      report_instance = @report.class_name.constantize.new
      @data = report_instance.get_data_from_result_list(@projects)
    end

    # This is the first year that the user can plan for
    @first_year = current_planning_year_year
    # This is the last year  the user can plan for
    @last_year = last_fiscal_year_year
    # This is an array of years that the user can plan for
    @years = (@first_year..@last_year).to_a

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @projects }
      format.xls
    end
  end

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


  def new

    add_breadcrumb "New", new_capital_project_path

    @project = CapitalProject.new
    @fiscal_years = get_fiscal_years

  end

  def edit

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb "Modify", edit_capital_project_path(@project)

    @fiscal_years = get_fiscal_years

  end

  def copy

    new_project = @project.dup
    new_project.object_key = nil
    new_project.save
    @project.activity_line_items.each do |ali|
      new_ali = ali.dup
      new_ali.object_key = nil
      new_project.activity_line_items << new_ali
    end

    notify_user(:notice, "Capital Project #{@project.project_number} was successfully copied to #{new_project.project_number}.")
    redirect_to capital_project_url(new_project)

  end

  def create

    add_breadcrumb "New", new_capital_project_path

    @project = CapitalProject.new(form_params)
    @project.organization = @organization
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

  def update

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb "Modify", edit_capital_project_path(@project)
    @fiscal_years = get_fiscal_years

    respond_to do |format|
      if @project.update_attributes(form_params)
        @project.update_project_number
        @project.save
        notify_user(:notice, "Capital Project #{@project.name} was successfully updated.")
        format.html { redirect_to capital_project_url(@project) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

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

  protected


  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:capital_project).permit(CapitalProject.allowable_params)
  end

  def get_project
    # See if it is our project
    @project = CapitalProject.find_by_object_key(params[:id]) unless params[:id].nil?
    # if not found or the object does not belong to the users
    # send them back to index.html.erb
    if @project.nil?
      notify_user(:alert, 'Record not found!')
      redirect_to(capital_projects_url)
      return
    end

  end

  def check_for_cancel
    unless params[:cancel].blank?
      # get the policy, if one was being edited
      if params[:id]
        redirect_to(capital_project_url(params[:id]))
      else
        redirect_to(capital_projects_url)
      end
    end
  end
end
