class CapitalProjectReportPresenter

  attr_accessor :projects
  attr_accessor :fy_year
  attr_accessor :multi_year_flag
  attr_accessor :sogr_flag
  attr_accessor :emergency_flag

  include TransamFormatHelper
  include FiscalYearHelper
  
  def organization_ids
    if projects.blank?
      []
    else
      projects.pluck(:organization_id).uniq
    end
  end

  # Convert to a hash, keyed by org
  def projects_by_organization
    @projects_by_organization ||= @projects.includes(:organization).group_by(&:organization)
  end

  def[](index)
    case index.to_s
      when 'labels'
        ['Org', get_fy_label, 'Project', 'Title', 'Scope', 'Cost', '# ALIs', '# Assets', 'Type', 'Emgcy', 'SOGR', 'Shadow', 'Multi Year']
      when 'data'
        data = []
        projects_by_organization.each do |org, projects|
          projects.each do |p|
            count_assets = 0
            p.activity_line_items.each{|x| count_assets += x.assets.count}
            row = [org.short_name]
            row << format_as_fiscal_year(p.fy_year)
            row << p.project_number
            row << p.title
            row << p.team_ali_code.scope
            row << p.total_cost
            row << p.activity_line_items.count
            row << count_assets
            row << p.capital_project_type.code
            row << (p.emergency? ? 'Y' : '')
            row << (p.sogr? ? 'Y' : '')
            row << (p.notional? ? 'Y' : '')
            row << (p.multi_year? ? 'Y' : '')
            data << row
          end
        end

        data
      when 'formats'
        [nil, nil, nil, nil, nil, :currency, nil, nil, nil, nil, nil, nil, nil]
      else
        []
    end
  end

end
