class CapitalPlansController < OrganizationAwareController

  def index
    # state view

    authorize! :read_all, CapitalPlan
  end

  def show
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


    actions = CapitalPlanAction.where(object_key: params[:targets].split(','))

    actions.each do |action|
      authorize! :update, action.capital_plan
      action.capital_plan_action_type.class_name.constantize.new(capital_plan_action: action, user: current_user).run
    end

    redirect_to :back
  end

  protected

  private
end
