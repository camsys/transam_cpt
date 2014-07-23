class ActivityLineItemsController < OrganizationAwareController

  # Include the team ali code mixin
  include AssetAliLookup

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path

  before_action :get_capital_project
  before_filter :check_for_cancel,        :only => [:create, :update]
  before_action :set_activity_line_item,  :only => [:show, :edit, :update, :destroy, :add_asset, :remove_asset, :edit_cost]

  INDEX_KEY_LIST_VAR    = "activity_line_item_key_list_cache_var"

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
    asset_subtypes = asset_subtypes_from_ali_code(@activity_line_item.team_ali_code.code)
    if asset_subtypes.empty?
      @assets = []
    else
      subtype_list = get_id_array(asset_subtypes)
      asset_list = get_id_array(@activity_line_item.assets)
      @assets = Asset.where('organization_id = ? AND scheduled_disposition_date IS NULL AND id NOT IN (?) AND asset_subtype_id IN (?) AND scheduled_replacement_year = ?', @project.organization.id, asset_list, subtype_list, @project.fy_year)
    end

    # Set up the cache list for the ALI
    cache_list(@project.activity_line_items, INDEX_KEY_LIST_VAR)
    
    # get the @prev_record_path and @next_record_path view vars
    get_next_and_prev_object_keys(@activity_line_item, INDEX_KEY_LIST_VAR)
    @prev_record_path = @prev_record_key.nil? ? "#" : capital_project_activity_line_item_path(@project, @prev_record_key)
    @next_record_path = @next_record_key.nil? ? "#" : capital_project_activity_line_item_path(@project, @next_record_key)

    # Load the eligibility service and use it to select funds which this ALI is eligible for
    eligibilityService = EligibilityService.new
    @available_funds = eligibilityService.evaluate(@activity_line_item)

  end

  # Add the specified asset to this ALI
  def add_asset
    asset = Asset.find_by_object_key(params[:asset])
    if asset.nil?
      notify_user(:alert, "Unable to add asset. Record not found!")
      return
    else
      @activity_line_item.assets << asset
      notify_user(:notice, "Asset was sucessfully added to the ALI")
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
      # force the ALI to update its estimated costs
      @activity_line_item.save
      notify_user(:notice, "Asset was sucessfully removed from the ALI")
    end
    redirect_to :back
  end

  # GET /activity_line_items/new
  def new

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb "New Activity Line Item", new_capital_project_activity_line_item_path(@project)

    @activity_line_item = ActivityLineItem.new
  end

  # GET /activity_line_items/1/edit
  def edit

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "Modify", capital_project_activity_line_item_path(@project, @activity_line_item)

  end

  # GET /activity_line_items/1/edit_cost
  def edit_cost

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "Modify", capital_project_activity_line_item_path(@project, @activity_line_item)

  end

  # POST /activity_line_items
  # POST /activity_line_items.json
  def create

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb "New Activity Line Item", new_capital_project_activity_line_item_path(@project)

    @activity_line_item = ActivityLineItem.new(form_params)
    @activity_line_item.capital_project = @project

    respond_to do |format|
      if @activity_line_item.save
        notify_user(:notice, "The ALI was successfully added to project #{@project.project_number}.")
        format.html { redirect_to capital_project_url(@project) }
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
        notify_user(:notice, "The ALI was successfully updated")
        format.html { redirect_to capital_project_activity_line_item_path(@project, @activity_line_item), notice: 'Activity line item was successfully updated.' }
        format.json { head :no_content }
      else
        if params[:activity_line_item][:anticipated_cost]
          format.html { render action: 'edit_cost' }
        else
          format.html { render action: 'edit' }
        end
        format.json { render json: @activity_line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activity_line_items/1
  # DELETE /activity_line_items/1.json
  def destroy
    @activity_line_item.destroy
    notify_user(:notice, "The ALI was successfully removed from project #{@project.project_number}.")
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
