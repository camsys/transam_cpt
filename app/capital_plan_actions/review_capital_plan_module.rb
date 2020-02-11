class ReviewCapitalPlanModule < BaseCapitalPlanModule

  def complete

    Delayed::Job.enqueue ReviewCapitalPlanModuleJob.new(@capital_plan_module), :priority => 0

  end
end