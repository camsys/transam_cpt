class CapitalProjectsController < OrganizationAwareController

  MAX_FORECASTING_YEARS = SystemConfig.instance.num_forecasting_years   

  # Include the fiscal year mixin
  include FiscalYear
    
  #before_filter :authorize_admin
  before_filter :check_for_cancel,  :only =>    [:create, :update, :runner]
  before_filter :get_project,       :except =>  [:index, :create, :new, :runner, :builder]
  
  SESSION_VIEW_TYPE_VAR = 'capital_projects_subnav_view_type'
    
  def builder
    @page_title = 'Capital Needs List Builder'
    @builder_proxy = BuilderProxy.new
    @message = "Creating capital projects. This process might take a while."
    
  end
  
  def runner
    
    @page_title = 'Capital Needs List Builder'
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

    @page_title = 'Capital Needs List'
    @fiscal_years = get_fiscal_years
   
     # Start to set up the query
    conditions  = []
    values      = []
    
    # Only for the selected organization
    conditions << 'organization_id = ?'
    values << @organization.id
    
    # See if we got search
    @fiscal_year = params[:fiscal_year]
    unless @fiscal_year.blank?
      @fiscal_year = @fiscal_year.to_i
      conditions << 'fy_year = ?'
      values << @fiscal_year
    end
    @team_scope_id = params[:team_scope_id]
    unless @team_scope_id.blank?
      @team_scope_id = @team_scope_id.to_i
      conditions << 'team_scope_code_id = ?'
      values << @team_scope_id
    end
    @status_type_id = params[:status_type_id]
    unless @status_type_id.blank?
      @status_type_id = @status_type_id.to_i
      conditions << 'capital_project_status_type_id = ?'
      values << @status_type_id
    end
    
    #puts conditions.inspect
    #puts values.inspect
    @projects = CapitalProject.where(conditions.join(' AND '), *values).order(:fy_year, :team_scope_code_id, :created_at)
      
    # remember the view type
    @view_type = get_view_type(SESSION_VIEW_TYPE_VAR)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @projects }
    end
  end

  def show

    @page_title = "Project: #{@project.project_number}"

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @project }
    end
  end

  
  def new
    
    @page_title = "New Capital Project"
    @project = CapitalProject.new
    
    @fiscal_years = get_fiscal_years
    
  end

  def edit
    
    @page_title = "Update #{@project.project_number}"
    @fiscal_years = get_fiscal_years
    
  end
  
  def create

    @project = CapitalProject.new(form_params)
    @project.organization = @organization
    @page_title = "New Capital Project"
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

    @page_title = "Update #{@project.project_number}"
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
