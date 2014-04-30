class CapitalProjectsController < OrganizationAwareController
  #before_filter :authorize_admin
  before_filter :check_for_cancel, :only => [:create, :update]
  before_filter :get_project, :except => [:index, :create, :new]
  
  SESSION_VIEW_TYPE_VAR = 'capital_projects_subnav_view_type'
    
  def index

    @page_title = 'Capital Needs List'
   
    # get the capital projects for this organizaitons 
    @projects = CapitalProject.where('organization_id = ? AND active = ?', @organization.id, true)
    
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
    
  end

  def edit
    
    @page_title = "Update #{@project.project_number}"
    
  end
  
  def create

    @project = CapitalProject.new(form_params)
    @project.organization = @organization
    @page_title = "New Capital Project"

    respond_to do |format|
      if @project.save
        # Update the record with a unique project number that uses the database id  
        @project.project_number = generate_project_number(@project)
        @project.save(:validate => :false)

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
  
  def generate_project_number(capital_project)
    year = Date.today.year - 2000
    "CCA-G-#{year}-#{year+1}-#{capital_project.organization.short_name}-#{capital_project.team_scope_code.code}-#{capital_project.id}"      
  end
  
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
