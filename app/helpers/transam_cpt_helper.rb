module TransamCptHelper

  # Return the version of TransAM CPT that is running
  def transam_cpt_version
    begin
      Gem.loaded_specs['transam_cpt'].version
    rescue
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