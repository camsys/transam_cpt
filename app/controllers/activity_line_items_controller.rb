class ActivityLineItemsController < OrganizationAwareController
  
  # Include the team ali code mixin
  include AssetAliLookup
  
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path
  
  before_action :get_capital_project
  before_filter :check_for_cancel,        :only => [:create, :update]
  before_action :set_activity_line_item,  :only => [:show, :edit, :update, :destroy, :add_asset, :remove_asset]
  
  # GET /activity_line_items
  # GET /activity_line_items.json
  def index

    # Render the project -> show action
    redirect_to capital_project_path(@project)
  end

  # GET /activity_line_items/1
  # GET /activity_line_items/1.json
  def show
    
    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)

    # Get the list of candidate assets that could be added to the ALI
    asset_subtype = asset_subtype_from_ali_code(@activity_line_item.team_ali_code.code)
    if asset_subtype.nil? 
      @assets = []
    else
      @assets = Asset.where('organization_id = ? AND asset_subtype_id = ? AND scheduled_replacement_year = ?', @project.organization.id, asset_subtype.id, @project.fy_year)
    end
    
    @page_title = "#{@project.project_number}: #{@activity_line_item.name}"  
  end

  # Add the specified asset to this ALI
  def add_asset
    asset = Asset.find_by_object_key(params[:asset])
    if asset.nil?
      notify_user(:alert, "Unable to add asset. Record not found!")
      return      
    else
      @activity_line_item.assets << asset
      notify_user(:notice, "Asset was sucesffully added to the ALI")
    end
    redirect_to :back
  end

  def remove_asset
    asset = Asset.find_by_object_key(params[:asset])
    if asset.nil?
      notify_user(:alert, "Unable to remove asset. Record not found!")
      return      
    else
      @activity_line_item.assets.delete(asset)
      notify_user(:notice, "Asset was sucessfully removed from the ALI")
    end
    redirect_to :back
  end
  
  # GET /activity_line_items/new
  def new

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb "New Activity Line Item", new_capital_project_activity_line_item_path(@project)

    @page_title = "#{@project.project_number}: New Activity Line Item"  
    @activity_line_item = ActivityLineItem.new
  end

  # GET /activity_line_items/1/edit
  def edit
    
    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "Modify", capital_project_activity_line_item_path(@project, @activity_line_item)

    @page_title = "#{@project.project_number}: Update Activity Line Item"  
  end

  # POST /activity_line_items
  # POST /activity_line_items.json
  def create
    
    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb "New Activity Line Item", new_capital_project_activity_line_item_path(@project)

    @activity_line_item = ActivityLineItem.new(form_params)
    @activity_line_item.capital_project = @project
    @page_title = "#{@project.project_number}: New Activity Line Item"  
    
    respond_to do |format|
      if @activity_line_item.save
        format.html { redirect_to capital_project_url(@project), notice: 'Activity line item was successfully created.' }
        format.json { render action: 'show', status: :created, location: @activity_line_item }
      else
        format.html { render action: 'new' }
        format.json { render json: @activity_line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /activity_line_items/1
  # PATCH/PUT /activity_line_items/1.json
  def update

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "Modify", capital_project_activity_line_item_path(@project, @activity_line_item)

    respond_to do |format|
      if @activity_line_item.update(form_params)
        format.html { redirect_to capital_project_activity_line_item_path(@project, @activity_line_item), notice: 'Activity line item was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @activity_line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activity_line_items/1
  # DELETE /activity_line_items/1.json
  def destroy
    @activity_line_item.destroy
    respond_to do |format|
      format.html { redirect_to capital_project_path(@project) }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_activity_line_item
      @activity_line_item = ActivityLineItem.find_by_object_key(params[:id])
    end

    def get_capital_project
      @project = CapitalProject.where('object_key = ?', params[:capital_project_id]).first unless params[:capital_project_id].blank?
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def form_params
      params.require(:activity_line_item).permit(activity_line_item_allowable_params)
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
