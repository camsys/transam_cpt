#------------------------------------------------------------------------------
#
# AssetSogrUpdateJob
#
# Updates an assets SOGR state
#
#------------------------------------------------------------------------------
class AssetSogrUpdateJob < AbstractAssetUpdateJob
  
  def execute_job(asset)       
    asset.update_sogr
    asset.reload

    # update asset and cost(s) in project planner
    service = CapitalProjectBuilder.new
    service.update_asset_schedule(asset)
  end

  def prepare
    Rails.logger.debug "Executing AssetSogrUpdateJob at #{Time.now.to_s} for Asset #{object_key}"    
  end
  
end