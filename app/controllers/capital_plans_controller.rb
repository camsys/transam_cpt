class CapitalPlansController < ApplicationController

  # Include the fiscal year mixin
  include FiscalYear

  before_action :get_capital_plan, except: :index
  before_action :setup_vars, only: [:show, :edit]

  def index
    # state view

    authorize! :read_all, CapitalPlan
  end

  def show
    # Single agency view
  end

  def edit
    # single agency view if you can edit the plan
  end

  def complete_actions
    actions = CapitalPlanAction.find_by(object_key: params[:targets].split(','))

    actions.each do |action|
      action.capital_action_type.class_name.constantize.new(capital_plan_action: action, user: current_user).run
    end
  end

  protected

  def get_capital_plan
    @capital_plan = CapitalPlan.find_by(object_key: params[id], organization_id: @organization_list)

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

  def setup_vars

    # pagination if needed
    if @organization_list.count > 1
      org_idx = @organization_list.index(@capital_plan.organization_id)
      @prev_record_path = org_idx == 0 ? "#" : capital_plan_path(CapitalPlan.current_plan(@organization_list[org_idx-1]))
      @next_record_path = org_idx == @organization_list.count-1 ? "#" : capital_plan_path(CapitalPlan.current_plan(@organization_list[org_idx+1]))
    end

    #update system actions
    @capital_plan.system_actions.each do |sys_action|
      sys_action.capital_action_type.class_name.constantize.new(capital_plan_action: sys_action, user: current_user).run
    end

  end

  private
end
