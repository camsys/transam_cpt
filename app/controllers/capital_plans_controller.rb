class CapitalPlansController < OrganizationAwareController

  before_action :get_capital_plan, only: [:show]

  def index
    # state view

    authorize! :read_all, CapitalPlan
  end

  def show
    authorize! :read, @capital_plan

    # pagination if needed
    if @organization_list.count > 1
      org_idx = @organization_list.index(@capital_plan.organization_id)
      @prev_record_path = org_idx == 0 ? "#" : capital_plan_path(CapitalPlan.current_plan(@organization_list[org_idx-1]))
      @next_record_path = org_idx == @organization_list.count-1 ? "#" : capital_plan_path(CapitalPlan.current_plan(@organization_list[org_idx+1]))
    end

    #update system actions
    @capital_plan.system_actions.each do |sys_action|
      sys_action.capital_plan_action_type.class_name.constantize.new(capital_plan_action: sys_action, user: current_user).run
    end
  end

  def complete_actions

    actions = CapitalPlanAction.where('(object_key IN (?) AND completed_at IS NULL) OR (object_key IN (?) AND completed_at IS NOT NULL)', params[:targets].split(','), params[:undo_targets].split(','))
    actions.each do |action|
      authorize! :update, action.capital_plan
      action.capital_plan_action_type.class_name.constantize.new(capital_plan_action: action, user: current_user).run
    end

    redirect_to :back
  end

  def get_checkboxes
    main_action = CapitalPlanAction.find_by(object_key: params[:capital_plan_action])

    # temporarily mark action as complete so can see what other actions would be now allowed
    main_action.update!(completed_at: Time.now)

    actions = CapitalPlanAction.where(object_key: params[:targets].split(','))
    checkbox_params = Hash.new
    actions.each do |a|
      checkbox_params[a.object_key] = Hash.new
      if a.completed?
        if !(a.is_undo_allowed? && (can? :complete_action, a))
          checkbox_params[a.object_key]['disabled'] = 'disabled'
        end
      else
        if !(a.is_allowed? && (can? :complete_action, a))
          checkbox_params[a.object_key]['disabled'] = 'disabled'
        end
      end
    end

    # reset completed at
    main_action.update!(completed_at: nil)

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

  private
end
