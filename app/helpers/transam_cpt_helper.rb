module TransamCptHelper

  # Return the version of TransAM CPT that is running
  def transam_cpt_version
    begin
      Gem.loaded_specs['transam_cpt'].version
    rescue
    end
  end

  #returns the budget remaining for the selected FY year for the selected org
  def get_remaining_budget(org, fy_year)
    1000
  end
  
end