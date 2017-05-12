class CapitalPlansController < ApplicationController

  # Include the fiscal year mixin
  include FiscalYear

  before_action :get_capital_plan, except: :index
  before_action :set_pagination, only: [:show, :edit]

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
      if action.is_allowed?
        action.capital_action_type.class_name.constantize.new.run

        # run next action in the plan if its a system step
        next_action_klass = action.next_action.capital_plan_action_type.constantize.new
        if next_action_klass.system_action?
          next_action_klass.run
        end
      end

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

  def set_pagination
    if @organization_list.count > 1
      org_idx = @organization_list.index(@capital_plan.organization_id)
      @prev_record_path = org_idx == 0 ? "#" : capital_plan_path(CapitalPlan.find_by(fy_year: current_planning_year_year, organization_id: @organization_list[org_idx-1]))
      @next_record_path = org_idx == @organization_list.count-1 ? "#" : capital_plan_path(CapitalPlan.find_by(fy_year: current_planning_year_year, organization_id: @organization_list[org_idx+1]))
    end
  end

  private
end
