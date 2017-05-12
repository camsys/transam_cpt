class AbstractCapitalPlanAction

  def run
    if pre_process
      complete
    end

    post_process
  end

  def pre_process
    return CapitalPlanActionType.find_by(class_name: self.class.name).is_allowed?
  end

  def complete
    # implemented at the concrete level
  end

  def post_process
    # implemented at the concrete level
  end

  def system_action?
    # usually false but can be overridden if system performs the step by default
    false
  end

end