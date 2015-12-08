class CapitalProjectReportPresenter

  attr_accessor :projects
  attr_accessor :fy_year
  attr_accessor :multi_year_flag
  attr_accessor :sogr_flag
  attr_accessor :emergency_flag

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
end
