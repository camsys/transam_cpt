class ActivityLineItemsController < OrganizationAwareController

  # Include the fiscal year mixin
  include FiscalYear

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path

  before_action :set_activity_line_item,  :only => [:show, :edit, :update, :destroy, :add_asset, :remove_asset,
                                                    :edit_cost, :restore_cost, :edit_milestones, :set_cost, :assets, :pin]
  before_action :get_capital_project
  before_action :reformat_date_fields,    :only => [:create, :update]

  INDEX_KEY_LIST_VAR    = "activity_line_item_key_list_cache_var"

  # GET /activity_line_items
  # GET /activity_line_items.json
  def index

    # Render the project -> show action
    redirect_to capital_project_path(@project)
  end

  # GET /activity_line_items/1
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

  end

  #
  # Not used
  # -----------------------------------------------------------------------------
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
    redirect_back(fallback_location: root_path)
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
    redirect_back(fallback_location: root_path)
  end
  # -----------------------------------------------------------------------------

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

  def pin
    if @activity_line_item.pinned?
      @activity_line_item.assets.update_all(replacement_status_type_id: ReplacementStatusType.find_by(name: 'By Policy').id)
    else
      @activity_line_item.assets.update_all(replacement_status_type_id: ReplacementStatusType.find_by(name: 'Pinned').id)
    end

    respond_to do |format|
      format.html {
        notify_user(:notice, "The ALI was successfully #{@activity_line_item.pinned? ? 'pinned' : 'unpinned'}.")
        redirect_back(fallback_location: root_path)
      }
      format.js
    end

  end

  # GET /activity_line_items/1/assets
  def assets

    add_breadcrumb @project.project_number, capital_project_path(@project)
    add_breadcrumb @activity_line_item.name, capital_project_activity_line_item_path(@project, @activity_line_item)
    add_breadcrumb "Assets"

    @fiscal_years = @activity_line_item.get_fiscal_years
    if CapitalPlan.current_plan(@project.organization_id) && CapitalPlan.current_plan(@project.organization_id).capital_plan_module_completed?(CapitalPlanModuleType.find_by(name: 'Constrained Plan').id)
      @fiscal_years = @fiscal_years[1..-1]
    end

    # enable dragging/dropping only if no background jobs
    @drag_drop_enabled = (Delayed::Job.where("failed_at IS NULL AND (handler LIKE ? OR handler LIKE ? OR handler LIKE ?)", "%MoveAliYearJob%", "%MoveAssetYearJob%", "%CapitalProjectBuilderJob%")
                              .map { |j| YAML.load(j.handler) })
                             .none? { |y| @project.organization_id == (y.instance_of?(CapitalProjectBuilderJob) ? y.organization.id : y.activity_line_item.organization_id) }

    # map sorting to correct fields
    sort_clause = ""
    if params[:sort]
      sort_clause =
          case params[:sort]
            when 'fuel_type'
              "fuel_types.code #{params[:order]}"
            when 'age'
              "assets.in_service_date #{params[:order].downcase == 'asc' ? 'desc' : 'asc'}"
            when 'policy_replacement_fiscal_year'
              "assets.policy_replacement_year #{params[:order]}"
            when 'scheduled_cost'
              "#{@activity_line_item.rehabilitation_ali? ? 'assets.estimated_rehabilitation_cost' : 'assets.scheduled_replacement_cost'} #{params[:order]}"
            else
              "#{params[:sort]} #{params[:order]}"
          end
    end

    respond_to do |format|
      format.js
      format.json {
        assets_json = @activity_line_item.assets.very_specific.limit(params[:limit]).offset(params[:offset]).order(sort_clause).collect{ |p|
          asset_policy_analyzer = p.policy_analyzer
          p.as_json(methods: [
              :reported_mileage,
              :reported_condition_rating,
              :age,
              :policy_replacement_year,
              :is_early_replacement?,
              :formatted_early_replacement_reason
          ]).merge!({
            asset_subtype: p.try(:asset_subtype).try(:to_s),
            fuel_type: p.try(:fuel_type).try(:code),
            in_backlog: p.in_backlog ? 1 : 0,
            policy_replacement_fiscal_year: fiscal_year(p.policy_replacement_year),
            scheduled_cost: @activity_line_item.rehabilitation_ali? ? p.estimated_rehabilitation_cost : p.scheduled_replacement_cost,
            estimated_cost: @activity_line_item.rehabilitation_ali? ? (@activity_line_item.rehabilitation_cost p) : (@activity_line_item.replacement_cost p),
            is_rehabilitated: !p.rehabilitation_updates.empty?,
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
    a = Rails.application.config.asset_base_class_name.constantize.get_typed_asset(Rails.application.config.asset_base_class_name.constantize.find_by(object_key: params[:asset_object_key]))

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
      format.html { redirect_back(fallback_location: root_path) }
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
        @activity_line_item.milestones.create(:milestone_type_id => mt.id)
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
        format.html { redirect_back(fallback_location: root_path) }
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
        format.js {
          notify_user(:notice, "The ALI was successfully updated")

          render(:partial => 'activity_line_items/update_cost', :formats => [:js] )
        }
        format.html {
          notify_user(:notice, "The ALI was successfully updated")
          redirect_back(fallback_location: root_path)
        }

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
        if (URI(request.referer || '').path.include?('planning') || URI(request.referer || '').path.include?('scheduler'))
          redirect_back(fallback_location: root_path)
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
        unless date_str.blank?
          form_date = Date.strptime(date_str, '%m/%d/%Y')
          milestone_hash[1]['milestone_date'] = form_date.strftime('%Y-%m-%d')
        end
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
    @project = params[:capital_project_id].blank? ? @activity_line_item.try(:capital_project) :CapitalProject.find_by(object_key: params[:capital_project_id], organization_id: @organization_list)

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
