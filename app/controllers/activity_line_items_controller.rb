class ActivityLineItemsController < OrganizationAwareController

  # Include the fiscal year mixin
  include FiscalYear

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path

  before_action :get_capital_project
  before_action :set_activity_line_item,  :only => [:show, :edit, :update, :destroy, :add_asset, :remove_asset,
                                                    :edit_cost, :restore_cost, :edit_milestones, :set_cost, :assets]
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
      notify_user(:notice, "Asset was successfully added to the ALI")
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
      notify_user(:notice, "Asset was successfully removed from the ALI")
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

  # GET /activity_line_items/1/assets
  def assets

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "Assets"

    @fiscal_years = @activity_line_item.get_fiscal_years

    # enable dragging/dropping only if no background jobs
    @drag_drop_enabled = (Delayed::Job.where("failed_at IS NULL AND handler LIKE ? AND (handler LIKE ? OR handler LIKE ?)", "%organization_id: #{@project.organization_id}%","%MoveAliYearJob%", "%MoveAssetYearJob%").count == 0)


    respond_to do |format|
      format.js
      format.json {
        assets_json = Asset.where(id: @activity_line_item.assets.ids).limit(params[:limit]).offset(params[:offset]).order(params[:sort] ? "#{params[:sort]} #{params[:order]}": "").collect{ |p|
          asset_policy_analyzer = p.policy_analyzer
          p.as_json.merge!({
            fuel_type: FuelType.find_by(id: p.fuel_type_id).try(:code),
            age: p.age,
            in_backlog: p.in_backlog,
            reported_mileage: p.reported_mileage,
            policy_replacement_year: p.policy_replacement_year,
            policy_replacement_fiscal_year: fiscal_year(p.policy_replacement_year),
            scheduled_cost: @activity_line_item.rehabilitation_ali? ? p.estimated_rehabilitation_cost : p.scheduled_replacement_cost,
            estimated_cost: @activity_line_item.rehabilitation_ali? ? (@activity_line_item.rehabilitation_cost p) : (@activity_line_item.replacement_cost p),
            is_early_replacement: p.is_early_replacement?,
            formatted_early_replacement_reason: p.formatted_early_replacement_reason,
            min_service_life: asset_policy_analyzer.get_min_service_life_months / 12,
            replace_with_subtype: asset_policy_analyzer.get_replace_asset_subtype_id.present? ? AssetSubtype.find_by(id: asset_policy_analyzer.get_replace_asset_subtype_id).to_s : false,
            replace_with_fuel_type: p.fuel_type_id != @activity_line_item.fuel_type_id ? @activity_line_item.fuel_type.code : false

          })
        }
        render :json => {
            :total => @activity_line_item.assets.count,
            :rows =>  assets_json
        }
      }
    end

  end

  def get_asset_summary
    a = Asset.find_by(object_key: params[:asset_object_key])

    respond_to do |format|
      #format.json { render json: {'html' => render_to_string(partial: 'assets/summary', locals: { :asset => a } ) } }
      format.js { render :partial => "assets/summary", locals: { :asset => a } }
    end
  end

  # GET /activity_line_items/1/edit_cost
  def edit_cost

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "Update Cost"

    # If they have not updated the cost before, we copy the estimated cost
    # to the anticipated cost
    @activity_line_item.anticipated_cost == @activity_line_item.cost

  end

  def restore_cost
    @activity_line_item.restore_estimated_cost
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
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
    if @activity_line_item.fy_year.blank?
      @activity_line_item.fy_year = @project.fy_year
    end

    respond_to do |format|
      if @activity_line_item.save
        notify_user(:notice, "The ALI was successfully added to project #{@project.project_number}.")
        format.html { redirect_to :back }
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
        #format.html { redirect_to capital_project_activity_line_item_path(@project, @activity_line_item), notice: 'Activity line item was successfully updated.' }
        format.html { redirect_to :back }

        text = "<div class='panel-body'>"+(render_to_string partial: 'planning/ali', formats: [:html], locals: { project: @activity_line_item.capital_project, ali: @activity_line_item, is_sogr: true }, layout: false )+"</div>"

        format.json { render json: {:new_html => text} }

      else
        if params[:activity_line_item][:cost]
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

        # check where to redirect to
        if URI(request.referer || '').path.include? 'planning'
          redirect_to :back
        else
          redirect_to capital_project_path(@project)
        end

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
        form_date = Date.strptime(date_str, '%m/%d/%Y')
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
    @project = CapitalProject.find_by(object_key: params[:capital_project_id], organization_id: @organization_list) unless params[:capital_project_id].blank?

    if @project.nil?
      if CapitalProject.find_by(object_key: params[:capital_project_id], :organization_id => current_user.user_organization_filters.system_filters.first.get_organizations.map{|x| x.id}).nil?
        redirect_to '/404'
      else
        notify_user(:warning, 'This record is outside your filter. Change your filter if you want to access it.')
        redirect_to capital_projects_path
      end
      return
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:activity_line_item).permit(ActivityLineItem.allowable_params)
  end

end
