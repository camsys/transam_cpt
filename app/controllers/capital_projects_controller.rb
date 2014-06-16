class CapitalProjectsController < OrganizationAwareController
   
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path
  
  MAX_FORECASTING_YEARS = SystemConfig.instance.num_forecasting_years   

  # Include the fiscal year mixin
  include FiscalYear
    
  #before_filter :authorize_admin
  before_filter :check_for_cancel,  :only =>    [:create, :update, :runner]
  before_filter :get_project,       :except =>  [:index, :create, :new, :runner, :builder]
  
  INDEX_KEY_LIST_VAR    = "capital_project_key_list_cache_var"
  SESSION_VIEW_TYPE_VAR = 'capital_projects_subnav_view_type'
    
  def builder

    add_breadcrumb "Capital Needs SOGR Builder", builder_capital_projects_path   
    
    @page_title = 'Capital Needs List Builder'
    @builder_proxy = BuilderProxy.new
    @message = "Creating SOGR capital projects. This process might take a while."
    
  end
  
  def runner

    add_breadcrumb "Capital Needs SOGR Builder", builder_capital_projects_path   
    @page_title = 'Capital Project Builder'

    @builder_proxy = BuilderProxy.new(params[:builder_proxy])
    if @builder_proxy.valid?
      # Sleep for a couple of seconds so that the screen can display the waiting 
      # message and the user can read it.
      sleep 2
      # Run the builder
      builder = CapitalProjectBuilder.new
      num_created = builder.build(@organization)
      # Let the user know the results
      if num_created > 0
        msg = "Capital Project Builder completed. #{num_created} projects were added to your capital needs list."
        notify_user(:notice, msg)
        # Add a row into the activity table
        ActivityLog.create({:organization_id => @organization.id, :user_id => current_user.id, :item_type => "CapitalProjectBuilder", :activity => msg, :activity_time => Time.now})
      else
        notify_user(:notice, "No projects were created.")
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

    @page_title = 'Unconstrained Capital Needs List'
    @fiscal_years = get_fiscal_years
   
     # Start to set up the query
    conditions  = []
    values      = []
    
    # Only for the selected organization
    conditions << 'organization_id IN (?)'
    values << @organization_list
    
    # See if we got search
    @fiscal_year = params[:fiscal_year]
    unless @fiscal_year.blank?
      @fiscal_year = @fiscal_year.to_i
      conditions << 'fy_year = ?'
      values << @fiscal_year
    end
    @status_type_id = params[:status_type_id]
    unless @status_type_id.blank?
      @status_type_id = @status_type_id.to_i
      conditions << 'capital_project_status_type_id = ?'
      values << @status_type_id
    end
    
    # Get the filter, if one is not found default to 0 
    @capital_project_type_id = params[:capital_project_type_id]
    if @capital_project_type_id.blank?
      @capital_project_type_id = 0
    else
      @capital_project_type_id = @capital_project_type_id.to_i
    end
    
    # See what type of filter we got. If the filter > 0 it is a capital project type
    # otherwise it is a grouping
    if @capital_project_type_id > 0
      capital_project_type = CapitalProjectType.find(@capital_project_type_id)
      conditions << 'capital_project_type_id = ?'
      values << @capital_project_type_id
      add_breadcrumb capital_project_type.name.pluralize(2), capital_projects_path(:capital_project_type_id => capital_project_type)    
    else
      if @capital_project_type_id == -1
        # all SOGR projects
        conditions << 'capital_project_type_id IN (?)'
        values << [1,2,3,4]
        add_breadcrumb "All SOGR Projects", capital_projects_path(:capital_project_type_id => -1)    
      elsif @capital_project_type_id == -2
        # all other projects
        conditions << 'capital_project_type_id IN (?)'
        values << [4,5,6,7,8,9]
        add_breadcrumb "All Other Projects", capital_projects_path(:capital_project_type_id => -2)    
      end
    end
    
    #puts conditions.inspect
    #puts values.inspect
    @projects = CapitalProject.where(conditions.join(' AND '), *values).order(:fy_year, :team_scope_code_id, :created_at)
      
    # cache the set of object keys in case we need them later
    cache_list(@projects, INDEX_KEY_LIST_VAR)
      
    # generate the chart data
    @report = Report.find_by_class_name('CapitalNeedsForecast')
    report_instance = @report.class_name.constantize.new
    @data = report_instance.get_data_from_result_list(@projects)
    
    # remember the view type
    @view_type = get_view_type(SESSION_VIEW_TYPE_VAR)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @projects }
    end
  end

  def show

    add_breadcrumb @project.project_number, capital_project_path(@project)    

    @page_title = "Project: #{@project.project_number}"

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
    
    @page_title = "New Capital Project"
    @project = CapitalProject.new
    
    @fiscal_years = get_fiscal_years
    
  end

  # Move a project forward or backward by the specified number of years.
  def shift_fiscal_year
    num_years = params[:num_years].to_i
    new_project_year = @project.fy_year + num_years
    # Check to see if they are attempting to move the project earlier than the current fiscal year
    if new_project_year < current_fiscal_year_year
      notify_user(:alert, "Project #{@project.project_number} can't be scheduled earlier than #{current_fiscal_year}.")
    else
      @project.fy_year = new_project_year
      @project.update_project_number
      @project.save
      notify_user(:notice, "The project was re-scheduled for #{@project.fy_year}. The new project number is #{@project.project_number}.")
    end
    if params[:view] == '1'
      redirect_to capital_projects_path
    else
      redirect_to capital_project_path(@project)
    end      
  end
  
  def edit

    add_breadcrumb @project.project_number, capital_project_path(@project)    
    add_breadcrumb "Modify", edit_capital_project_path(@project)    
    
    @page_title = "Update #{@project.project_number}"
    @fiscal_years = get_fiscal_years
    
  end
  
  def create

    add_breadcrumb "New", new_capital_project_path    
    @page_title = "New Capital Project"

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
    @page_title = "Modify #{@project.project_number}"
    @fiscal_years = get_fiscal_years

    respond_to do |format|
      if @project.update_attributes(form_params)
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
      format.html { redirect_to capital_projects_url }
      format.json { head :no_content }
    end
  end
  
  protected
    
      
  private
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:capital_project).permit(capital_project_allowable_params)
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
