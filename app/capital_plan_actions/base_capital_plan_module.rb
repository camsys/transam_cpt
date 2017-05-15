class BaseCapitalPlanModule

  attr_accessor :capital_plan_module
  attr_accessor :user

  def run
    if pre_process
      complete

      post_process
    end
  end

  def pre_process
    return @capital_plan_module.is_allowed?
  end

  def complete
    # implemented at the concrete level
  end

  def post_process
    @capital_plan_module.update(completed_at: Time.now, completed_by_user_id: @user.id)
  end

  private

  def initialize(args = {})
    args.each do |k, v|
      self.send "#{k}=", v
    end
  end


end