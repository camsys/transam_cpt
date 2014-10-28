class SchedulerController < OrganizationAwareController

  before_filter :set_view_vars,  :only =>    [:index, :loader, :scheduler_action, :scheduler_ali_action,
    :edit_asset_in_modal]

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Scheduler", :scheduler_index_path

  # Include the fiscal year mixin
  include FiscalYear

  # Controller actions that can be invoked from the view
  REPLACE_ACTION              = '1'
  REHABILITATE_ACTION         = '2'
  REMOVE_FROM_SERVICE_ACTION  = '3'
  RESET_ACTION                = '4'

  ACTIONS = [
    ["Replace", REPLACE_ACTION],
    ["Rehabilitate", REHABILITATE_ACTION],
    ["Remove from service (no replacement)", REMOVE_FROM_SERVICE_ACTION],
    ["Reset to policy", RESET_ACTION]
  ]

  YES = '1'
  NO = '0'

  BOOLEAN_SELECT = [
    ['Yes', YES],
    ['No', NO]
  ]

  # Returns the list of assets that are scheduled for replacement/rehabilitation in the given
  # fiscal years.
  def index

    # Get the ALIs for each year
    @year_1_alis = get_alis(@year_1)
    @year_2_alis = get_alis(@year_2)
    @year_3_alis = get_alis(@year_3)

  end

  # Process a request to load a scheduler update form. This is ajaxed
  def loader

    @asset = Asset.find_by_object_key(params[:id])
    @current_year = params[:year].to_i

    @actions = ACTIONS

    @fiscal_years = []
    (@year_1..@year_1 + 3).each do |yr|
      @fiscal_years << [fiscal_year(yr), yr]
    end
    @proxy = SchedulerActionProxy.new
    @proxy.set_defaults(@asset)

  end

  # Render the partial for the asset edit modal.
  def edit_asset_in_modal
    # TODO refactor with code in #loader, above.
    # #loader can possibly go away
    @asset = Asset.find_by_object_key(params[:id])
    @current_year = params[:year].to_i

    @actions = ACTIONS

    @fiscal_years = []
    (@year_1..@year_1 + 3).each do |yr|
      @fiscal_years << [fiscal_year(yr), yr]
    end
    @proxy = SchedulerActionProxy.new
    @proxy.set_defaults(@asset)

    render partial: 'edit_asset_in_modal'
  end

  # Render the partial for the update cost modal.
  def update_cost_modal
    @capital_project = CapitalProject.where(object_key: params[:capital_project]).first
    @ali = ActivityLineItem.where(object_key: params[:ali]).first
    render partial: 'update_cost_modal'
  end

  # Process a scheduler action. These are generally ajaxed
  def scheduler_action

    proxy = SchedulerActionProxy.new(params[:scheduler_action_proxy])

    asset = Asset.find_by_object_key(proxy.object_key)

    # TODO DWH This is just a placeholder for now to prevent this blowing up when I hand it an ALI.  Will be completed.
    if asset.nil?
      render json: {}
      return
    end

    case proxy.action_id
    when REPLACE_ACTION
    when 'move_asset_to_fiscal_year'
      Rails.logger.debug "Updating asset #{asset.object_key}. New scheduled replacement year = #{proxy.fy_year.to_i}"
      asset.scheduled_replacement_year = proxy.fy_year.to_i if proxy.fy_year
      asset.replacement_reason_type_id = proxy.reason_id.to_i if proxy.reason_id
      asset.scheduled_replacement_cost = proxy.replace_cost.to_i if proxy.replace_cost
      asset.scheduled_replace_with_new = proxy.replace_with_new.to_i if proxy.replace_with_new
      asset.save
      #notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} #{asset.description} is scheduled for replacement in #{fiscal_year(proxy.year.to_i)}"

    when REHABILITATE_ACTION
      asset.scheduled_rehabilitation_year = proxy.fy_year.to_i
      asset.scheduled_replacement_year = asset.scheduled_rehabilitation_year + proxy.extend_eul_years.to_i
      asset.scheduled_rehabilitation_cost = proxy.rehab_cost.to_i
      asset.save
      #notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} #{asset.description} is now scheduled for replacement in #{fiscal_year(proxy.replace_fy_year.to_i)}"

    when REMOVE_FROM_SERVICE_ACTION
      asset.scheduled_rehabilitation_year = nil
      asset.scheduled_replacement_year = nil
      asset.scheduled_replacement_cost = nil
      asset.scheduled_replace_with_new = nil
      asset.scheduled_rehabilitation_cost = nil
      asset.scheduled_disposition_year = proxy.fy_year.to_i
      asset.save

    when RESET_ACTION
      asset.scheduled_rehabilitation_year = nil
      asset.scheduled_replacement_year = asset.policy_replacement_year
      asset.scheduled_disposition_year = nil
      asset.scheduled_replacement_cost = nil
      asset.scheduled_replace_with_new = nil
      asset.scheduled_rehabilitation_cost = nil
      asset.save

    end

    # Update the capital projects with this new data
    builder = CapitalProjectBuilder.new
    builder.update_asset_schedule(asset)

    # Get the ALIs for each year
    @year_1_alis = get_alis(@year_1)
    @year_2_alis = get_alis(@year_2)
    @year_3_alis = get_alis(@year_3)

  end

  def scheduler_ali_action
    p = params[:scheduler_action_proxy]

    CapitalProjectBuilder.move_ali_to_planning_year(p[:object_key], p[:fy_year])

    # Get the ALIs for each year
    @year_1_alis = get_alis(@year_1)
    @year_2_alis = get_alis(@year_2)
    @year_3_alis = get_alis(@year_3)

    render :scheduler_action

  end
  
  protected

  # Sets the view variables that control the filters. called before each action is invoked
  def set_view_vars

    @org_id = params[:org_id].blank? ? nil : params[:org_id].to_i

    # This is the first year that the user can plan for
    first_year = current_fiscal_year_year + 1
    # This is the last year of a 3 year plan
    last_year = last_fiscal_year_year - 2
    # This is an array of years that the user can plan for
    years = (first_year..last_year).to_a

    # Set the view up. Start year is the first year in the view
    @start_year = params[:start_year].blank? ? first_year : params[:start_year].to_i
    @year_1 = @start_year
    @year_2 = @start_year + 1
    @year_3 = @start_year + 2

    # Add ability to page year by year
    @total_rows = years.size
    # get the index of the start year in the array
    current_index = years.index(@start_year)
    @row_number = current_index + 1
    if current_index == 0
      @prev_record_path = "#"
    else
      @prev_record_path = scheduler_index_path(:start_year => @start_year - 1, :asset_subtype_id => @asset_subtype_id, :org_id => @org_id)
    end
    if current_index == (@total_rows - 1)
      @next_record_path = "#"
    else
      @next_record_path = scheduler_index_path(:start_year => @start_year + 1, :asset_subtype_id => @asset_subtype_id, :org_id => @org_id)
    end
    @row_pager_remote = true

  end

  def get_alis(year)

    # check to see if there is a filter on the organization
    org = @org_id.blank? ? @organization.id : @org_id
    projects = CapitalProject.where('organization_id = ? AND fy_year = ?', org, year)

    alis = ActivityLineItem.where(:capital_project_id => projects)
    alis
  end

  private

end
