class PlanningController < OrganizationAwareController

  before_filter :set_view_vars,  :only => [:index, :move_assets, :asset_action, :ali_action, :add_funds, :update_cost, :edit_asset]

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Planning", :planning_index_path

  # Include the fiscal year mixin
  include FiscalYear

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

  # Returns the list of assets that are scheduled for replacement/rehabilitation in the given
  # fiscal year.
  def index
    # check to see if there is a filter on the organization
    org = @org_id.blank? ? @organization.id : @org_id
    @projects = CapitalProject.where(:organization_id => org).order(:fy_year)
  end

  def load_chart

    @funding_source = FundingSource.find_by_object_key(params[:fund])
    report = BudgetBurndown.new
    @data = report.get_data(@organization, {:funding_source => @funding_source})

    respond_to do |format|
      format.js
      format.json { render :json => @data.to_json }
    end
  end

  # Render the partial for the asset edit modal.
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

  # Render the partial for the update cost modal.
  def update_cost

    @ali = ActivityLineItem.where(object_key: params[:ali]).first

    render :partial => 'update_cost_modal_form'
  end

  # Render the partial for adding a funding plan to the ALI
  def add_funds

    @ali = ActivityLineItem.find_by_object_key(params[:ali])
    @budget_amounts = @organization.budget_amounts.where('fy_year = ? AND amount > 0', @ali.capital_project.fy_year)

    render :partial => 'add_funds_modal_form'
  end

  # Processes a bulk move of assets from one FY to another
  def move_assets

    @activity_line_item = ActivityLineItem.find_by(:object_key => params[:ali])
    @fy_year = params[:year].to_i
    if @activity_line_item.present? and @fy_year > 0
      service = CapitalProjectBuilder.new
      assets = @activity_line_item.assets.where(:object_key => params[:targets])
      assets.each do |a|
        # Replace or Rehab?
        if @activity_line_item.rehabilitation_ali?
          a.scheduled_rehabilitation_year = @fy_year
        else
          a.scheduled_replacement_year = @fy_year
        end
        a.save(:validate => false)
        a.reload
        service.update_asset_schedule(a)
      end
      notify_user :notice,  "Moved #{assets.count} assets to #{fiscal_year(@fy_year)}"
    else
      notify_user :alert,  "Missing ALI or fy_year. Can't perform update."
    end

    # check to see if there is a filter on the organization
    org = @org_id.blank? ? @organization.id : @org_id
    @projects = CapitalProject.where(:organization_id => org).order(:fy_year)

  end

  # Process a scheduler action for an asset. This must be called using a JS action
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
      CapitalProjectBuilder.new.move_ali_to_planning_year(@activity_line_item, new_fy_year)
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

    # check to see if there is a filter on the organization
    org = @org_id.blank? ? @organization.id : @org_id
    @projects = CapitalProject.where(:organization_id => org).order(:fy_year)

  end

  protected

  # Sets the view variables that control the filters. called before each action is invoked
  def set_view_vars

    @org_id = params[:org_id].blank? ? nil : params[:org_id].to_i

    # This is the first year that the user can plan for
    @first_year = current_planning_year_year
    # This is the last year  the user can plan for
    @last_year = last_fiscal_year_year
    # This is an array of years that the user can plan for
    @years = (@first_year..@last_year).to_a


  end

  private

end
