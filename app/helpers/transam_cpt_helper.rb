module TransamHelper

  # Return the version of TransAM CPT that is running
  def transam_cpt_version
    begin
      Gem.loaded_specs['transam_cpt'].version
    rescue
    end
  end

end