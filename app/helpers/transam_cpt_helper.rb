module TransamCptHelper

  # Include the fiscal year mixin
  include FiscalYear

  # Return the version of TransAM CPT that is running
  def transam_cpt_version
    begin
      Gem.loaded_specs['transam_cpt'].version
    rescue
    end
  end

  def sum_projects_cost_by_year projects
    alis = projects.joins(:activity_line_items)
    anticipated_cost_by_year = alis.where("anticipated_cost > 0").group("activity_line_items.fy_year").sum(:anticipated_cost) 
    estimated_cost_by_year = alis.where.not("anticipated_cost > 0").group("activity_line_items.fy_year").sum(:estimated_cost)
    
    # merge and sum by same year
    anticipated_cost_by_year.merge!(estimated_cost_by_year) { |k, o, n| o + n }
  end

  def sum_projects_cost projects, year
    val = 0
    projects.each{|x| val += x.total_cost(year)}
    val
  end
  # Returns a fiscal year array for a project
  def get_project_fiscal_years project
    if project.blank?
      []
    elsif project.multi_year?
      a = []
      get_fiscal_years.each do |fy|
        if fy[1] < project.fy_year
          next
        else
          a << fy
        end
      end
      a
    else
      [[project.fiscal_year, project.fy_year]]
    end
  end

  # Returns the correct icon for a workflow asset
  def get_event_icon(event_name)

    if event_name == 'retract'
      'fa-reply'
    elsif event_name == 'submit'
      'fa-share'
    elsif event_name == 'approve'
      'fa-plus-square'
    elsif event_name == 'return'
      'fa-chevron-circle-left'
    else
      ''
    end
  end

  # Returns the correct cost for a swimlane/asset/year
  def get_swimlane_activity_cost(asset, year)

    if asset.scheduled_disposition_year == year
      # nothing to display
      return nil
    elsif asset.scheduled_replacement_year == year
      cost = asset.scheduled_replacement_cost.present? ? asset.scheduled_replacement_cost : asset.policy_rule.replacement_cost
    elsif asset.scheduled_rehabilitation_year == year
      cost = asset.scheduled_rehabilitation_cost.present? ? asset.scheduled_rehabilitation_cost : asset.policy_rule.rehabilitation_cost
    else
      cost = 0
    end
    format_as_currency(cost)
  end

  # Returns the correct swimlane icon color for an asset
  def get_swimlane_icon(asset, year)

    if asset.scheduled_disposition_year == year
      'fa-times-circle'
    elsif asset.scheduled_rehabilitation_year == year
      'fa-wrench'
    elsif asset.scheduled_replacement_year == year
      'fa-refresh'
    else
      'fa-warning'
    end
  end

  # Returns the correct swimlane panel color for an asset
  def get_swimlane_class(asset, year)
    if asset.in_backlog?
      'panel-default'
    elsif asset.scheduled_replacement_year and asset.scheduled_replacement_year < asset.policy_replacement_year
      'panel-warning'
    else
      'panel-info'
    end
  end

end
