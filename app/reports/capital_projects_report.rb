#------------------------------------------------------------------------------
#
# Capital Projects Report
#
# Generates a report of capital projects with breakdown by ALIs
#
#------------------------------------------------------------------------------
class CapitalProjectsReport < AbstractReport

  # include the fiscal year mixin
  include FiscalYear

  attr_accessor :fy_year

  # returns assets, along with some meta-information (FY)
  def get_data(organization_id_list, params)

    Rails.logger.debug "In CapitalProjectsReport"
    Rails.logger.debug organization_id_list.inspect
    Rails.logger.debug params.inspect

    output = CapitalProjectReportPresenter.new

    output.fy_year = params[:fy_year].to_i
    output.emergency_flag = params[:emergency_flag].to_i
    output.multi_year_flag = params[:multi_year_flag].to_i
    output.sogr_flag = params[:sogr_flag].to_i

    output.projects = get_capital_projects organization_id_list, output

    return output
  end


  def initialize(attributes = {})
    super(attributes)
    set_defaults
  end

  def get_capital_projects(organization_id_list, output)

    # Start to set up the query
    conditions  = []
    values      = []

    conditions << 'organization_id IN (?)'
    values << organization_id_list

    if output.emergency_flag == 1
      conditions << 'emergency = ?'
      values << true
    elsif output.emergency_flag == 2
      conditions << 'emergency = ?'
      values << false
    end
    if output.sogr_flag == 1
      conditions << 'sogr = ?'
      values << true
    elsif output.sogr_flag == 2
      conditions << 'sogr = ?'
      values << false
    end
    if output.multi_year_flag == 1
      conditions << 'multi_year = ?'
      values << true
    elsif output.multi_year_flag == 2
      conditions << 'multi_year = ?'
      values << false
    end
    if output.fy_year > 0
      conditions << 'fy_year = ?'
      values << output.fy_year
    end
    CapitalProject.where(conditions.join(' AND '), *values).order(:organization_id, :fy_year, :team_ali_code_id)
  end

  def set_defaults
  end
end
