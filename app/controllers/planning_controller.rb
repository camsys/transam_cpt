#-------------------------------------------------------------------------------
# PlanningController
#
#
#-------------------------------------------------------------------------------
class PlanningController < AbstractCapitalProjectsController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Planning", :planning_index_path

  # Controller actions that can be invoked from the view to manuipulate assets
  ASSET_REPLACE_ACTION              = '1'
  ASSET_REHABILITATE_ACTION         = '2'
  ASSET_REMOVE_FROM_SERVICE_ACTION  = '3'
  ASSET_RESET_ACTION                = '4'

  # Controller actions that can be invoked from the view to manuipulate ALIs
  ALI_MOVE_YEAR_ACTION    = '1'
  ALI_UPDATE_COST_ACTION  = '2'
  ALI_REMOVE_ACTION       = '3'
  ALI_ADD_FUND_ACTION     = '4'
  ALI_REMOVE_FUND_ACTION  = '5'

  ACTIONS = [
    ["Replace", ASSET_REPLACE_ACTION],
    ["Rehabilitate", ASSET_REHABILITATE_ACTION],
    ["Remove from service (no replacement)", ASSET_REMOVE_FROM_SERVICE_ACTION],
    ["Reset to policy", ASSET_RESET_ACTION]
  ]

  YES = '1'
  NO = '0'

  BOOLEAN_SELECT = [
    ['Yes', YES],
    ['No', NO]
  ]

  #-----------------------------------------------------------------------------
  # Returns the list of assets that are scheduled for replacement/rehabilitation in the given
  # fiscal year.
  #-----------------------------------------------------------------------------
  def index
    prepare_projects_display
    
  end

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  def load_chart

    @funding_source = FundingSource.find_by_object_key(params[:fund])
    report = BudgetBurndown.new
    @data = report.get_data(@organization, {:funding_source => @funding_source})

    respond_to do |format|
      format.js
      format.json { render :json => @data.to_json }
    end
  end

  #-----------------------------------------------------------------------------
  # Render the partial for the asset edit modal.
  #-----------------------------------------------------------------------------
  def edit_asset

    @asset = Asset.find_by_object_key(params[:id])
    @actions = ACTIONS

    @fiscal_years = []
    (current_planning_year_year..last_fiscal_year_year).each do |yr|
      @fiscal_years << [fiscal_year(yr), yr]
    end
    @proxy = SchedulerActionProxy.new
    @proxy.set_defaults(@asset)

    render :partial => 'edit_asset_modal_form'
  end

  #-----------------------------------------------------------------------------
  # Render the partial for the update cost modal.
  #-----------------------------------------------------------------------------
  def update_cost

    @ali = ActivityLineItem.where(object_key: params[:ali]).first

    render :partial => 'update_cost_modal_form'
  end

  #-----------------------------------------------------------------------------
  # Render the partial for adding a funding plan to the ALI
  #-----------------------------------------------------------------------------
  def add_funds

    @ali = ActivityLineItem.find_by_object_key(params[:ali])
    @budget_amounts = @organization.budget_amounts.where('fy_year = ? AND amount > 0', @ali.capital_project.fy_year)

    render :partial => 'add_funds_modal_form'
  end

  #-----------------------------------------------------------------------------
  # Processes a bulk move of assets from one FY to another
  #-----------------------------------------------------------------------------
  def move_assets

    @job_finished = false

    @activity_line_item = ActivityLineItem.find_by(:object_key => params[:ali])
    @fy_year = params[:year].to_i
    if @activity_line_item.present? and @fy_year > 0
      Delayed::Job.enqueue AssetScheduleJob.new(@activity_line_item, @fy_year, params[:targets], current_user, params[:early_replacement_reason]), :priority => 0

      sleep 10 # pause action for 10 seconds to let job finish if its small

      # if job finishes run JS and reload project planner with moved assets
      # otherwise notify user that background job is running
      job_notification = Notification.find_by(notifiable_type: 'ActivityLineItem', notifiable_id: @activity_line_item.id)
      if job_notification.nil?
        notify_user :notice, "Assets are being moved. You will be notified when the process is complete."
      else
        notify_user :notice, job_notification.text
        job_notification.update(active: false)
        @job_finished = true
        prepare_projects_display
      end

    else
      notify_user :alert,  "Missing ALI or fy_year. Can't perform update."
    end

  end

  #-----------------------------------------------------------------------------
  # Process a scheduler action for an asset. This must be called using a JS action
  #-----------------------------------------------------------------------------
  def asset_action

    #proxy = SchedulerActionProxy.new(params[:scheduler_action_proxy])

    case proxy.action_id
    when ASSET_REPLACE_ACTION
      Rails.logger.debug "Updating asset #{asset.object_key}. New scheduled replacement year = #{proxy.fy_year.to_i}"
      asset.scheduled_replacement_year = proxy.fy_year.to_i if proxy.fy_year
      asset.replacement_reason_type_id = proxy.reason_id.to_i if proxy.reason_id
      asset.scheduled_replacement_cost = proxy.replace_cost.to_i if proxy.replace_cost
      asset.scheduled_replace_with_new = proxy.replace_with_new.to_i if proxy.replace_with_new
      updated = true
      asset.save
      #notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} #{asset.description} is scheduled for replacement in #{fiscal_year(proxy.year.to_i)}"

    when ASSET_REHABILITATE_ACTION
      asset.scheduled_rehabilitation_year = proxy.fy_year.to_i
      asset.scheduled_replacement_year = asset.scheduled_rehabilitation_year + proxy.extend_eul_years.to_i
      asset.scheduled_rehabilitation_cost = proxy.rehab_cost.to_i
      updated = true
      asset.save
      #notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} #{asset.description} is now scheduled for replacement in #{fiscal_year(proxy.replace_fy_year.to_i)}"

    when ASSET_REMOVE_FROM_SERVICE_ACTION
      asset.scheduled_rehabilitation_year = nil
      asset.scheduled_replacement_year = nil
      asset.scheduled_replacement_cost = nil
      asset.scheduled_replace_with_new = nil
      asset.scheduled_rehabilitation_cost = nil
      asset.scheduled_disposition_year = proxy.fy_year.to_i
      updated = true
      asset.save

    when ASSET_RESET_ACTION
      asset.scheduled_rehabilitation_year = nil
      asset.scheduled_replacement_year = asset.policy_replacement_year
      asset.scheduled_disposition_year = nil
      asset.scheduled_replacement_cost = nil
      asset.scheduled_replace_with_new = nil
      asset.scheduled_rehabilitation_cost = nil
      updated = true
      asset.save

    end

    # Update the capital projects with this new data
    if updated
      CapitalProjectBuilder.new.update_asset_schedule(asset)
    end

  end

  #-----------------------------------------------------------------------------
  # General purpose action for mamipulating ALIs in the plan. This action
  # must be called as JS
  #-----------------------------------------------------------------------------
  def ali_action

    @activity_line_item = ActivityLineItem.find_by(:object_key => params[:ali])
    action = params[:invoke]

    case action
    when ALI_MOVE_YEAR_ACTION
      new_fy_year = params[:year]
      Rails.logger.debug "Moving ali #{@activity_line_item} to new FY #{new_fy_year}"
      CapitalProjectBuilder.new.move_ali_to_planning_year(@activity_line_item, new_fy_year, params[:early_replacement_reason])
      notify_user :notice, "The ALI was successfully moved to #{new_fy_year}."

    when ALI_UPDATE_COST_ACTION
      @activity_line_item.anticipated_cost = params[:activity_line_item][:anticipated_cost]
      Rails.logger.debug "Updating anticipated cost for ali #{@activity_line_item} to  #{params[:activity_line_item][:anticipated_cost]}"
      if @activity_line_item.save
        notify_user :notice,  "The ALI was successfully updated."
      else
        notify_user :alert,  "An error occurred while updating the ALI."
      end

    when ALI_REMOVE_ACTION
      @project = @activity_line_item.capital_project
      @activity_line_item.destroy
      Rails.logger.debug "Removing ali #{@activity_line_item} from project #{@project}"
      notify_user :notice,  "The ALI was successfully removed from project #{@project.project_number}."

    when ALI_ADD_FUND_ACTION
      budget_amount = BudgetAmount.find(params[:source])
      amount = params[:amount].to_i

      # Add a funding plan to this ALI
      @activity_line_item.funding_plans.create({:budget_amount => budget_amount, :amount => amount})
      notify_user :notice,  "The ALI was successfully updated."

    when ALI_REMOVE_FUND_ACTION
      fp = FundingPlan.find_by_object_key(params[:funding_plan])
      @activity_line_item.funding_plans.delete fp
      notify_user :notice,  "The ALI was successfully updated."
    end

    prepare_projects_display

  end

  #-----------------------------------------------------------------------------
  protected
  #-----------------------------------------------------------------------------
  # prepare data and sessions for displaying projects on planner page
  def prepare_projects_display
    # query projects
    get_projects

    # check if reaches threshold
    @project_display_threshold_reached = @projects.count > max_projects_display_threshold
    
    # when reach the threshold, we only display one year's projects at a time
    # pass :display_fy_year in URL to request for a year's projects
    @display_fy_year = if !@project_display_threshold_reached
      # if not reach the max threshold, then display projects in all years
      nil
    elsif !params[:display_fy_year].blank?
      # otherwise, check if explicity param exist in URL
      params[:display_fy_year].to_i 
    elsif !session[:display_fy_year].blank?
      # otherwise, use previous session
      session[:display_fy_year]
    else
      # otherwise, use first available year
      @years.first
    end

    # update session
    session[:display_fy_year] = @display_fy_year

    # projects to display at a time
    # if only display for a year, then:
    #    - for multi_year project, use fy_year <= @display_fy_year
    #    - for single year project, use fy_year == @display_fy_year
    @display_projects = @projects
    
    @display_projects = @display_projects.where("
      (capital_projects.multi_year != 1 AND capital_projects.fy_year = ?) OR 
      (capital_projects.multi_year = 1 AND capital_projects.fy_year <= ?)", 
      @display_fy_year, @display_fy_year) if @display_fy_year
    
    notify_user(:notice, "Showing projects for #{fiscal_year(@display_fy_year)}. Click a FY to see projects for that year.", now: true) if @project_display_threshold_reached 
  end

  #-----------------------------------------------------------------------------
  private
  #-----------------------------------------------------------------------------
  
  # max amount of projects on planner page
  def max_projects_display_threshold
    if Rails.application.config.respond_to?(:max_count_display_on_project_planner) 
      config_value = Rails.application.config.max_count_display_on_project_planner
      if config_value.is_a?(Integer) &&  config_value > 0
        return config_value
      end
    end

    100
  end

end
