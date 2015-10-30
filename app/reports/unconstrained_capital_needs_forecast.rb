class UnconstrainedCapitalNeedsForecast < AbstractReport

  # Include the fiscal year mixin
  include FiscalYear

  def initialize(attributes = {})
    super(attributes)
  end

  def get_data_from_result_list(capital_project_list)

    # Capital Needs by year
    a = []
    labels = ['Fiscal Year']
    labels << "Capital Needs"

    (current_planning_year_year..last_fiscal_year_year).each do |year|
      row = []
      row << fiscal_year(year)
      total = 0
      # get the capital projects for this analysis year and state
      capital_projects =  capital_project_list.where('fy_year = ?', year)
      capital_projects.find_each do |cp|
        total += cp.total_cost
      end
      row << total
      a << row
    end

    return {:labels => labels, :data => a}

  end

  def get_data(organization_id_list, params)

    capital_projects = CapitalProject.where('capital_projects.organization_id IN (?)', organization_id_list)
    return get_data_from_result_list(capital_projects)

  end

end
