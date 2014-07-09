class FundingRequestsController < OrganizationAwareController
    
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path
  
  before_action :get_capital_project
  before_action :get_activity_line_item
  before_filter :check_for_cancel,        :only => [:create, :update]
  before_action :set_funding_request,     :only => [:show, :edit, :update, :destroy]
  
  # GET /funding_requests
  # GET /funding_requests.json
  def index

    # Render the project -> show action
    redirect_to capital_project_activity_line_item_path(@project, @activity_line_item)
    
  end

  # GET /funding_requests/1
  # GET /funding_requests/1.json
  def show
    
    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb @funding_request.name
    
  end
  
  # GET /funding_requests/new
  def new

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "New Funding Request"

    @funding_request = FundingRequest.new
  end

  # GET /funding_requests/1/edit
  def edit
    
    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb @funding_request.name, capital_project_funding_request_path(@project, @funding_request)
    add_breadcrumb "Modify"

  end

  # POST /funding_requests
  # POST /funding_requests.json
  def create
    
    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "New Funding Request"

    @funding_request = FundingRequest.new(form_params)
    @funding_request.activity_line_item = @activity_line_item
    @funding_request.creator = current_user
    @funding_request.updator = current_user
        
    respond_to do |format|
      if @funding_request.save
        notify_user(:notice, "The Funding Request was successfully added to project #{@project.project_number}.")
        format.html { redirect_to capital_project_url(@project) }
        format.json { render action: 'show', status: :created, location: @funding_request }
      else
        format.html { render action: 'new' }
        format.json { render json: @funding_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /funding_requests/1
  # PATCH/PUT /funding_requests/1.json
  def update

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb @funding_request.name, capital_project_funding_request_path(@project, @funding_request)
    add_breadcrumb "Modify"

    # Record who updated the record
    @funding_request.updator = current_user

    respond_to do |format|
      if @funding_request.update(form_params)
        notify_user(:notice, "The Funding Request was successfully updated")
        format.html { redirect_to capital_project_activity_line_item_path(@project, @funding_request) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @funding_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /funding_requests/1
  # DELETE /funding_requests/1.json
  def destroy
    @funding_request.destroy
    notify_user(:notice, "The funding request was successfully removed from project #{@project.project_number}.")
    respond_to do |format|
      format.html { redirect_to capital_project_path(@project) }
      format.json { head :no_content }
    end
  end

  private
  
  # Use callbacks to share common setup or constraints between actions.
  def set_funding_request
    @funding_request = FundingRequest.find_by_object_key(params[:id])
  end

  def set_activity_line_item
    @activity_line_item = ActivityLineItem.where('object_key = ?', params[:activity_line_item_id]).first unless params[:activity_line_item_id].blank?
  end

  def get_capital_project
    @project = CapitalProject.where('object_key = ?', params[:capital_project_id]).first unless params[:capital_project_id].blank?
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:funding_request).permit(funding_request_item_allowable_params)
  end

  def check_for_cancel
    unless params[:cancel].blank?
      # get the ali, if one was being edited
      if params[:id]
        redirect_to(capital_project_activity_line_item_path(@project, params[:id]))
      else
        redirect_to(capital_project_url(@project))
      end
    end
  end

end
