#-------------------------------------------------------------------------------
# UnconstrainedCapitalNeedsForecast
#
# As capital projects can span multiple years, this report needs to summarize
# ALI costs for each project within each fiscal year
#
#-------------------------------------------------------------------------------
class UnconstrainedCapitalNeedsForecast < AbstractReport

  # Include the fiscal year mixin
  include FiscalYear

  #-----------------------------------------------------------------------------
  def initialize(attributes = {})
    super(attributes)
  end

  #-----------------------------------------------------------------------------
  # Main method that takes a list of capital projects and summarizes the ALI costs
  # Returns an array of arrays
  #-----------------------------------------------------------------------------
  def get_data_from_result_list(capital_project_list)

    # Capital Needs by year
    a = []
    labels = ['Fiscal Year']
    labels << "Capital Needs"

    # Get a unique list of capital project ids
    capital_project_ids = capital_project_list.pluck(:id).uniq

    (current_planning_year_year..last_fiscal_year_year).each do |year|
      row = []
      row << fiscal_year(year)
      # get the capital projects for this analysis year and state
      alis = ActivityLineItem.where('fy_year = ? AND capital_project_id IN (?)', year, capital_project_ids)
      total = alis.sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)
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
