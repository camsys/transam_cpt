class ActivityLineItemsController < OrganizationAwareController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path

  before_action :get_capital_project
  before_action :set_activity_line_item,  :only => [:show, :edit, :update, :destroy, :add_asset, :remove_asset,
                                                    :edit_cost, :edit_milestones, :set_cost]
  before_filter :reformat_date_fields,    :only => [:create, :update]

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
    matcher = AliAssetMatcherService.new
    @assets = matcher.match(@activity_line_item, {})

    # Set up the cache list for the ALI
    cache_list(@project.activity_line_items, INDEX_KEY_LIST_VAR)

    # get the @prev_record_path and @next_record_path view vars
    get_next_and_prev_object_keys(@activity_line_item, INDEX_KEY_LIST_VAR)
    @prev_record_path = @prev_record_key.nil? ? "#" : capital_project_activity_line_item_path(@project, @prev_record_key)
    @next_record_path = @next_record_key.nil? ? "#" : capital_project_activity_line_item_path(@project, @next_record_key)

    # Load the eligibility service and use it to select funds which this ALI is eligible for
    eligibility_service = EligibilityService.new
    @funding_sources = eligibility_service.evaluate_organization_funding_sources(@organization)

    #@available_federal_funds = []
    #@available_state_funds   = []
    # eligibilityService.evaluate(@activity_line_item, {:federal => true}).each do |fli|
    #   amount = view_context.format_as_currency(fli.available)
    #   if fli.project_number.blank?
    #     name = "#{fli.funding_source} #{fli.fiscal_year} (#{amount})"
    #   else
    #     name = "#{fli.funding_source} #{fli.fiscal_year}: #{fli.project_number} (#{amount})"
    #   end
    #   @available_federal_funds << [name, fli.id]
    # end
    # eligibilityService.evaluate(@activity_line_item, {:state => true}).each do |fli|
    #   amount = view_context.format_as_currency(fli.available)
    #   if fli.project_number.blank?
    #     name = "#{fli.funding_source} #{fli.fiscal_year} (#{amount})"
    #   else
    #     name = "#{fli.funding_source} #{fli.fiscal_year}: #{fli.project_number} (#{amount})"
    #   end
    #   @available_state_funds << [name, fli.id]
    # end

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
    add_breadcrumb "Modify"

  end

  # GET /activity_line_items/1/edit_cost
  def edit_cost

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "Update Cost"

  end

  # GET /activity_line_items/1/edit_milestones
  def edit_milestones

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "Update Milestones"

    # Check to see if any milestones have been added, if not we create them
    if @activity_line_item.milestones.empty?
      today = Date.today
      # see which set of milestones we need based on the ALI
      if @activity_line_item.team_ali_code.is_vehicle_delivery?
        milestone_types = MilestoneType.vehicle_delivery_milestones
      else
        milestone_types = MilestoneType.other_project_milestones
      end
      milestone_types.all.each do |mt|
        @activity_line_item.milestones.create(:milestone_type_id => mt.id, :milestone_date => today)
      end
    end

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
    msg = "The ALI was successfully removed from project #{@project.project_number}."
    project_ali_count = @project.activity_line_items.count
    year = @project.fy_year
    respond_to do |format|
      format.js {
        notify_user(:notice, msg)
      }
      format.html {
        notify_user(:notice, msg)
        redirect_to capital_project_path(@project)
      }
    end
  end

  private

  def reformat_date_fields

    unless params[:activity_line_item][:milestones_attributes].blank?
      #puts 'Before reformat'
      #puts params[:activity_line_item][:milestones_attributes].inspect

      params[:activity_line_item][:milestones_attributes].each do |milestone_hash|
        #puts milestone_hash.inspect
        date_str = milestone_hash[1]['milestone_date']
        form_date = Date.strptime(date_str, '%m-%d-%Y')
        milestone_hash[1]['milestone_date'] = form_date.strftime('%Y-%m-%d')
      end

      #puts 'After reformat'
      #puts params[:activity_line_item][:milestones_attributes].inspect

    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_activity_line_item
    @activity_line_item = ActivityLineItem.find_by_object_key(params[:id])
  end

  def get_capital_project
    @project = CapitalProject.where('object_key = ?', params[:capital_project_id]).first unless params[:capital_project_id].blank?
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:activity_line_item).permit(ActivityLineItem.allowable_params)
  end

end
