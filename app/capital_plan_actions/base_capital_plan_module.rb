class BaseCapitalPlanModule

  attr_accessor :capital_plan_module
  attr_accessor :user

  def run
    if @capital_plan_module.completed_at.nil?
      if pre_process
        complete

        post_process
      end
    else
      if undo_pre_process
        undo_complete

        undo_post_process
      end
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

  def undo_pre_process
    return @capital_plan_module.is_allowed?
  end

  def undo_complete

  end

  def undo_post_process
    @capital_plan_module.update(completed_at: nil, completed_by_user_id: @user.id)
  end

  private

  def initialize(args = {})
    args.each do |k, v|
      self.send "#{k}=", v
    end
  end


end