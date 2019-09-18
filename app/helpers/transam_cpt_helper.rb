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

  # Returns a fiscal year array for a project
  def get_project_fiscal_years project
    if project.blank?
      []
    elsif project.multi_year?
      a = []
      (current_fiscal_year_year..current_fiscal_year_year + 49).map{ |y| [fiscal_year(y), y] }.each do |fy|
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
    cost
  end

end
