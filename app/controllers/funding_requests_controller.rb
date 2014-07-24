class FundingRequestsController < OrganizationAwareController

  add_breadcrumb "Home", :root_path

  before_action :get_capital_project
  before_action :get_activity_line_item
  before_filter :check_for_cancel,        :only => [:create, :update]
  before_action :set_funding_request,     :only => [:show, :edit, :update, :destroy]
  
  # Include the fiscal year mixin
  include FiscalYear

  INDEX_KEY_LIST_VAR    = "funding_requests_key_list_cache_var"
  
  # GET /funding_requests
  # GET /funding_requests.json
  def index

    add_breadcrumb "Funding Requests"

    @fiscal_years = get_fiscal_years
   
     # Start to set up the query
    conditions  = []
    values      = []
        
    # Check to see if we got an organization to sub select on. 
    @org_filter = params[:org_id]
    conditions << 'organization_id IN (?)'
    if @org_filter.blank?
      values << @organization_list      
    else
      @org_filter = @org_filter.to_i
      values << [@org_filter]
    end

    # See if we got fiscal year
    @fiscal_year = params[:fiscal_year]
    unless @fiscal_year.blank?
      @fiscal_year = @fiscal_year.to_i
      conditions << 'fy_year = ?'
      values << @fiscal_year
    end
    
    # See if we got a capital project type
    @capital_project_type_id = params[:capital_project_type_id]
    unless @capital_project_type_id.blank?
      @capital_project_type_id = @capital_project_type_id.to_i
      conditions << 'capital_project_type_id = ?'
      values << @capital_project_type_id
    end

    # Get the funding source filter if there is one
    @funding_source_id = params[:funding_source_id]
    if @funding_source_id.blank?
      @funding_source_id = 0
    else
      @funding_source_id = @funding_source_id.to_i
    end
        
    # We have to build the list of funding requests by iterating through the
    # set of matching capital projects    
    @funding_requests = []
    projects = CapitalProject.where(conditions.join(' AND '), *values).order(:fy_year, :capital_project_type_id)
    projects.each do |project|
      project.activity_line_items.each do |ali|
        ali.funding_requests.each do |request|
          # If we got a funding source fitler, check that this request is for that source
          if @funding_source_id > 0
            if request.funding_amount.funding_source_id == @funding_source_id
              @funding_requests << request 
            end
          else
            # no funding source filter
            @funding_requests << request
          end
        end
      end
    end  
      
    unless params[:format] == 'xls'
      # cache the set of object keys in case we need them later
      cache_list(@funding_requests, INDEX_KEY_LIST_VAR)        
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @funding_requests }
      format.xls
    end
        
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
        notify_user(:notice, "The Funding Request was successfully added to ALI #{@activity_line_item.name}.")
        # See if the capital proejct is fully funded
        if @funding_request.activity_line_item.funding_difference == 0
          notify_user(:notice, "ALI #{@activity_line_item.name} is fully funded.")          
        end
        if @funding_request.activity_line_item.capital_project.funding_difference == 0
          capital_project = @funding_request.activity_line_item.capital_project
          capital_project.capital_project_status_type = CapitalProjectStatusType.find_by_name('Programmed')
          capital_project.save
          notify_user(:notice, "Capital Project #{capital_project.name} is fully funded.")          
        end
        format.html { redirect_to capital_project_activity_line_item_url(@project, @activity_line_item) }
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

    # Save the capital project
    capital_project = @funding_request.activity_line_item.capital_project
    @funding_request.destroy
    notify_user(:notice, "The Funding Request was successfully removed from ALI #{@activity_line_item.name}.")

    # Check to see if the capital project status needs to change after removing
    # the funding request
    if capital_project.funding_difference != 0
      capital_project.capital_project_status_type = CapitalProjectStatusType.find_by_name('Unprogrammed')
      capital_project.save
    end
    
    respond_to do |format|
      format.html { redirect_to capital_project_activity_line_item_url(@project, @activity_line_item) }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_funding_request
    @funding_request = FundingRequest.find_by_object_key(params[:id])
  end

  def get_activity_line_item
    @activity_line_item = ActivityLineItem.where('object_key = ?', params[:activity_line_item_id]).first unless params[:activity_line_item_id].blank?
  end

  def get_capital_project
    @project = CapitalProject.where('object_key = ?', params[:capital_project_id]).first unless params[:capital_project_id].blank?
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:funding_request).permit(funding_request_allowable_params)
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
