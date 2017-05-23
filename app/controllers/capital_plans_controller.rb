class CapitalPlansController < OrganizationAwareController

  before_action :get_capital_plan, only: [:show]

  def index
    # state view

    authorize! :read_all, CapitalPlan
    add_breadcrumb 'Capital Plans', capital_plans_path


    @capital_plans = []
    TransitOperator.where(id: @organization_list).each do |org|
      plan = CapitalPlan.current_plan(org.id)
      @capital_plans << plan
      run_system_actions(plan)
    end
  end

  def show
    authorize! :read, @capital_plan

    # pagination if needed
    org_list = TransitOperator.where(id: @organization_list).ids # only use transit agencies
    if org_list.count > 1
      if can? :read_all, CapitalPlan
        add_breadcrumb 'Capital Plans', capital_plans_path
      end

      @total_rows = org_list.count
      org_idx = org_list.index(@capital_plan.organization_id)
      @row_number = org_idx+1
      @prev_record_key = CapitalPlan.current_plan(org_list[org_idx-1]).object_key if org_idx > 0
      @next_record_key = CapitalPlan.current_plan(org_list[org_idx+1]).object_key if org_idx < org_list.count - 1

      @prev_record_path = @prev_record_key.nil? ? "#" : capital_plan_path(@prev_record_key)
      @next_record_path = @next_record_key.nil? ? "#" : capital_plan_path(@next_record_key)
    end

    add_breadcrumb @capital_plan, capital_plan_path(@capital_plan)

    run_system_actions(@capital_plan)

  end

  def complete_actions

    actions = CapitalPlanAction.where('(capital_plan_actions.object_key IN (?) AND capital_plan_actions.completed_at IS NULL) OR (capital_plan_actions.object_key IN (?) AND capital_plan_actions.completed_at IS NOT NULL)', params[:targets].split(','), params[:undo_targets].split(','))
    actions.each do |action|
      authorize! :update, action.capital_plan
      action.capital_plan_action_type.class_name.constantize.new(capital_plan_action: action, user: current_user).run
    end

    respond_to do |format|
      format.js { render text: URI(request.referer) }
    end
  end

  def get_checkboxes
    checked = params[:checked_targets].split(',')

    unless checked.any?
      checked = [nil]
    end

    capital_plan = CapitalPlan.find_by(object_key: params[:id])

    checkbox_params = Hash.new
    capital_plan.capital_plan_actions.each do |a|
      checkbox_params[a.object_key] = Hash.new
      if checked.include? a.object_key
        if !(a.is_undo_allowed?(checked) && (can? :complete_action, a))
          checkbox_params[a.object_key]['disabled'] = 'disabled'
        end
      else
        if !(a.is_allowed?(checked) && (can? :complete_action, a))
          checkbox_params[a.object_key]['disabled'] = 'disabled'
        end
      end
    end

    respond_to do |format|
      format.json { render json: checkbox_params.to_json }
    end
  end

  protected

  def get_capital_plan
    @capital_plan = CapitalPlan.find_by(object_key: params[:id], organization_id: @organization_list)

    if @capital_plan.nil?
      if CapitalPlan.find_by(object_key: params[:id], :organization_id => current_user.user_organization_filters.system_filters.first.get_organizations.map{|x| x.id}).nil?
        redirect_to '/404'
      else
        notify_user(:warning, 'This record is outside your filter. Change your filter if you want to access it.')
        redirect_to capital_plans_path
      end
      return
    end
  end

  def run_system_actions(plan)
    plan.system_actions.each do |sys_action|
      sys_action.capital_plan_action_type.class_name.constantize.new(capital_plan_action: sys_action, user: current_user).run
    end
  end

  private
end
