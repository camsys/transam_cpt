module TransamCptHelper

  # Return the version of TransAM CPT that is running
  def transam_cpt_version
    begin
      Gem.loaded_specs['transam_cpt'].version
    rescue
    end
  end

  # Returns the correct swimlane icon color for an asset
  def get_swimlane_icon(asset, year)
    
    if asset.scheduled_disposition_date and asset.scheduled_disposition_date.year == year
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